// External scanner for tree-sitter-jac (hand-written C).
//
// This is the ONE hand-authored native file in the project; the grammar itself
// is authored in Jac (grammar.jac -> src/grammar.json) and src/parser.c is
// generated. The scanner supplies tokens whose boundaries the context-free
// grammar cannot express, because they require unbounded, context-sensitive
// lexing:
//
//   * PYINLINE       -- a `::py:: ... ::py::` inline-Python block (PYNLINE).
//   * JSX_TEXT       -- raw character data between JSX tags (up to `<`/`{`/`}`).
//   * FSTRING_START  -- the prefix + opening quote of an f-string (`f"`, `rf'''`).
//   * FSTRING_CONTENT-- a run of literal f-string text between interpolations.
//   * FSTRING_END    -- the closing quote of an f-string.
//
// The TokenType enum order MUST match the `externals` array in grammar.jac.
//
// f-strings carry state: the quote character and triple-ness of every f-string
// currently open (they nest: `f"{f'{x}'}"`). That stack is serialized so
// tree-sitter can restore it across speculative lexing.

#include "tree_sitter/parser.h"

#include <stdlib.h>
#include <wctype.h>

enum TokenType {
  PYINLINE,
  JSX_TEXT,
  FSTRING_START,
  FSTRING_CONTENT,
  FSTRING_END,
};

#define MAX_FSTRING_DEPTH 24

typedef struct {
  char quote;   // '"' or '\''
  bool triple;  // """ / ''' delimited
} FString;

typedef struct {
  FString stack[MAX_FSTRING_DEPTH];
  uint8_t depth;
} Scanner;

// ---------------------------------------------------------------------------
// Lifecycle + serialization
// ---------------------------------------------------------------------------

void *tree_sitter_jac_external_scanner_create(void) {
  Scanner *s = (Scanner *)malloc(sizeof(Scanner));
  if (s) {
    s->depth = 0;
  }
  return s;
}

void tree_sitter_jac_external_scanner_destroy(void *payload) { free(payload); }

unsigned tree_sitter_jac_external_scanner_serialize(void *payload, char *buffer) {
  Scanner *s = (Scanner *)payload;
  unsigned n = 0;
  buffer[n++] = (char)s->depth;
  for (uint8_t i = 0; i < s->depth; i++) {
    buffer[n++] = s->stack[i].quote;
    buffer[n++] = (char)(s->stack[i].triple ? 1 : 0);
  }
  return n;
}

void tree_sitter_jac_external_scanner_deserialize(void *payload, const char *buffer,
                                                  unsigned length) {
  Scanner *s = (Scanner *)payload;
  s->depth = 0;
  if (length == 0) {
    return;
  }
  unsigned n = 0;
  s->depth = (uint8_t)buffer[n++];
  for (uint8_t i = 0; i < s->depth; i++) {
    s->stack[i].quote = buffer[n++];
    s->stack[i].triple = buffer[n++] != 0;
  }
}

// ---------------------------------------------------------------------------
// `::py::` inline-Python block
// ---------------------------------------------------------------------------

static const char PY_MARK[] = {':', ':', 'p', 'y', ':', ':'};
static const int PY_MARK_LEN = 6;
// KMP longest-proper-prefix-suffix table for "::py::" (fallback uses LPS[m-1]).
static const int PY_LPS[] = {0, 1, 0, 0, 1, 2};

static bool scan_pyinline(TSLexer *lexer) {
  while (iswspace(lexer->lookahead)) {
    lexer->advance(lexer, true);
  }
  for (int i = 0; i < PY_MARK_LEN; i++) {
    if (lexer->lookahead != (int32_t)PY_MARK[i]) {
      return false;
    }
    lexer->advance(lexer, false);
  }
  int m = 0;
  while (!lexer->eof(lexer)) {
    int32_t c = lexer->lookahead;
    while (m > 0 && c != (int32_t)PY_MARK[m]) {
      m = PY_LPS[m - 1];
    }
    if (c == (int32_t)PY_MARK[m]) {
      m++;
    }
    lexer->advance(lexer, false);
    if (m == PY_MARK_LEN) {
      lexer->mark_end(lexer);
      lexer->result_symbol = PYINLINE;
      return true;
    }
  }
  return false;
}

// ---------------------------------------------------------------------------
// JSX raw text
// ---------------------------------------------------------------------------

static bool scan_jsx_text(TSLexer *lexer) {
  while (iswspace(lexer->lookahead)) {
    lexer->advance(lexer, true);
  }
  bool has_text = false;
  while (!lexer->eof(lexer)) {
    int32_t c = lexer->lookahead;
    if (c == '<' || c == '{' || c == '}') {
      break;
    }
    lexer->advance(lexer, false);
    has_text = true;
    lexer->mark_end(lexer);
  }
  if (has_text) {
    lexer->result_symbol = JSX_TEXT;
    return true;
  }
  return false;
}

// ---------------------------------------------------------------------------
// f-strings
// ---------------------------------------------------------------------------

// `f"`, `F'`, `rf"""`, `fr'`, ... -- prefix letters that must include f/F,
// followed by a single or triple quote. Pushes the open f-string onto the stack.
static bool scan_fstring_start(TSLexer *lexer, Scanner *s) {
  if (s->depth >= MAX_FSTRING_DEPTH) {
    return false;
  }
  // The scanner is invoked before extras are stripped, so skip any leading
  // whitespace (as extras) to reach the `f`/`r`/`b` prefix.
  while (iswspace(lexer->lookahead)) {
    lexer->advance(lexer, true);
  }
  bool has_f = false;
  while (true) {
    int32_t c = lexer->lookahead;
    if (c == 'f' || c == 'F') {
      has_f = true;
      lexer->advance(lexer, false);
    } else if (c == 'r' || c == 'R' || c == 'b' || c == 'B') {
      lexer->advance(lexer, false);
    } else {
      break;
    }
  }
  if (!has_f) {
    return false;
  }
  int32_t q = lexer->lookahead;
  if (q != '"' && q != '\'') {
    return false;
  }
  lexer->advance(lexer, false);  // opening quote
  lexer->mark_end(lexer);        // tentatively a single-quote start
  bool triple = false;
  if (lexer->lookahead == q) {
    lexer->advance(lexer, false);  // 2nd quote (beyond mark_end for now)
    if (lexer->lookahead == q) {
      lexer->advance(lexer, false);  // 3rd quote -> triple
      lexer->mark_end(lexer);
      triple = true;
    }
    // else: an empty f-string `f""`; the 2nd quote is re-lexed as FSTRING_END.
  }
  s->stack[s->depth].quote = (char)q;
  s->stack[s->depth].triple = triple;
  s->depth++;
  lexer->result_symbol = FSTRING_START;
  return true;
}

// Scan the body of an open f-string, emitting EITHER one FSTRING_CONTENT run or
// the FSTRING_END quote. Done in a single pass (not two functions) because
// tree-sitter only resets the lexer position between scan() calls, not within
// one -- so distinguishing a lone quote (content) from the closing `"""` must
// not leave the cursor stranded for a following sub-scanner.
//
// `{{`/`}}` are escapes kept as content; a single `{`/`}` ends the content so
// the grammar can take the interpolation. `\x` escapes never close the string.
static bool scan_fstring_body(TSLexer *lexer, Scanner *s, const bool *valid) {
  FString ctx = s->stack[s->depth - 1];
  bool has = false;
  while (!lexer->eof(lexer)) {
    int32_t c = lexer->lookahead;

    if (c == '{' || c == '}') {
      lexer->advance(lexer, false);  // past the first brace
      if (lexer->lookahead == c) {   // `{{` / `}}` -> literal content
        lexer->advance(lexer, false);
        has = true;
        lexer->mark_end(lexer);
        continue;
      }
      // single brace -> interpolation boundary; content (if any) ends before it.
      if (has) {
        lexer->result_symbol = FSTRING_CONTENT;
        return true;
      }
      return false;  // no content; reset -> the grammar lexes the `{`/`}`
    }

    if (c == '\\') {
      lexer->advance(lexer, false);
      if (!lexer->eof(lexer)) {
        lexer->advance(lexer, false);
      }
      has = true;
      lexer->mark_end(lexer);
      continue;
    }

    if (c == (int32_t)ctx.quote) {
      if (!ctx.triple) {
        if (has) {
          lexer->result_symbol = FSTRING_CONTENT;
          return true;
        }
        if (!valid[FSTRING_END]) {
          break;  // quote where no end is expected -- bail to other tokens
        }
        lexer->advance(lexer, false);
        lexer->mark_end(lexer);
        lexer->result_symbol = FSTRING_END;
        s->depth--;
        return true;
      }
      // Triple: only a run of three quotes closes; 1 or 2 are content.
      lexer->advance(lexer, false);  // 1st quote
      if (lexer->lookahead != (int32_t)ctx.quote) {  // lone quote -> content
        has = true;
        lexer->mark_end(lexer);
        continue;
      }
      lexer->advance(lexer, false);  // 2nd quote
      if (lexer->lookahead != (int32_t)ctx.quote) {  // two quotes -> content
        has = true;
        lexer->mark_end(lexer);
        continue;
      }
      // Three quotes -> the closing delimiter.
      if (has) {
        // Content ends before the run; the quotes (beyond mark_end) re-lex.
        lexer->result_symbol = FSTRING_CONTENT;
        return true;
      }
      if (!valid[FSTRING_END]) {
        break;
      }
      lexer->advance(lexer, false);  // 3rd quote
      lexer->mark_end(lexer);
      lexer->result_symbol = FSTRING_END;
      s->depth--;
      return true;
    }

    lexer->advance(lexer, false);
    has = true;
    lexer->mark_end(lexer);
  }
  if (has) {
    lexer->result_symbol = FSTRING_CONTENT;
    return true;
  }
  return false;
}

// ---------------------------------------------------------------------------

bool tree_sitter_jac_external_scanner_scan(void *payload, TSLexer *lexer,
                                           const bool *valid_symbols) {
  Scanner *s = (Scanner *)payload;

  // Inside an open f-string, content/end take priority over everything else.
  if (s->depth > 0 &&
      (valid_symbols[FSTRING_CONTENT] || valid_symbols[FSTRING_END])) {
    if (scan_fstring_body(lexer, s, valid_symbols)) {
      return true;
    }
  }

  if (valid_symbols[FSTRING_START] && scan_fstring_start(lexer, s)) {
    return true;
  }
  if (valid_symbols[JSX_TEXT] && scan_jsx_text(lexer)) {
    return true;
  }
  if (valid_symbols[PYINLINE]) {
    return scan_pyinline(lexer);
  }
  return false;
}
