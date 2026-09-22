# Step 3 report: idiomize (py2jac floor -> idiomatic Jac)

**Date:** 2026-08-05  
**Idiomize model:** Pi agent (rules in `scripts/step3_idiomize_prompt.md`)  
**Guard:** `jac test` against the record's step-2 test blocks (model never sees tests)  
**Samples:** 5  
**Keep ratio (idiomatic passed guard):** 5/5

## Per-record

| ID | entrypoint | idiomatic kept | reason |
|----|------------|----------------|--------|
| 295211 | `pysiphash` | yes |  |
| 207145 | `isFrozen` | yes |  |
| 377941 | `csim_to_scamp5` | yes |  |
| 313569 | `_extract_url_and_sha_from_deps_entry` | yes |  |
| 147075 | `_isIPv4Addr` | yes |  |

## Floor vs. idiomatic diffs

### 295211 `pysiphash` — KEPT
```diff
--- floor
+++ idiomatic
@@ -1,14 +1,17 @@
-"""Convert SipHash24 output to Py_hash_t
-    """
-def pysiphash(uint64: Any) -> object {
-    assert (0 <= uint64 < (1 << 64));
-    if (uint64 > ((1 << 63) - 1)) {
+glob INT64_MAX = (1 << 63) - 1;
+glob UINT32_MASK = 0xFFFFFFFF;
+glob INT32_MAX = (1 << 31) - 1;
+
+"""Convert SipHash24 output to Py_hash_t."""
+def pysiphash(uint64: int) -> tuple[int, int] {
+    assert 0 <= uint64 < (1 << 64);
+    if uint64 > INT64_MAX {
         int64 = uint64 - (1 << 64);
     } else {
         int64 = uint64;
     }
-    uint32 = (uint64 ^ (uint64 >> 32)) & 4294967295;
-    if (uint32 > ((1 << 31) - 1)) {
+    uint32 = (uint64 ^ (uint64 >> 32)) & UINT32_MASK;
+    if uint32 > INT32_MAX {
         int32 = uint32 - (1 << 32);
     } else {
         int32 = uint32;
```

### 207145 `isFrozen` — KEPT
```diff
--- floor
+++ idiomatic
@@ -1,9 +1,4 @@
-"""
-    Return a boolean indicating whether the given status name is frozen or not.
-
-    @type status: C{unicode}
-    @rtype: C{bool}
-    """
-def isFrozen(status: Any) -> object {
+"""Return whether the given status name is frozen."""
+def isFrozen(status: str) -> bool {
     return status.startswith('.');
 }
```

### 377941 `csim_to_scamp5` — KEPT
```diff
--- floor
+++ idiomatic
@@ -1,50 +1,37 @@
+"""Map a CSIM program (AUKE output) to a SCAMP5 program.
+
+When double_shifts is True, shifting instructions are rewritten to their
+double_ variants.
 """
-  Takes a CSIM program as a list of instructions (strings),
-  and maps it to a SCAMP5 program.
-  program: list of instructions, ['instr1', 'instr2', '// comment', ...]. Should
-    be the exact output of AUKE (we here rely on its specific syntax, such as
-    whitespace location etc.)
-  doubleShifts: boolean, if True shifting instructions are replaced
-    by double_shifting instructions (see macros in .hpp file)
-  """
-def csim_to_scamp5(program: Any, doubleShifts: Any = False) -> object {
-    outputProgram = [];
-    if doubleShifts {
-        shiftPrefix = 'double_';
-    } else {
-        shiftPrefix = '';
-    }
+def csim_to_scamp5(program: list[str], double_shifts: bool = False) -> list[str] {
+    output_program: list[str] = [];
+    shift_prefix = 'double_' if double_shifts else '';
     for instr in program {
         if instr.startswith('_transform') {
             instr = '// ' + instr;
-        } elif (
-            instr.startswith('// north')
-            or instr.startswith('// east')
-            or instr.startswith('// south')
-            or instr.startswith('// west')
-        ) {
-            instr = shiftPrefix + instr[3:];
+        } elif instr.startswith(('// north', '// east', '// south', '// west')) {
+            instr = shift_prefix + instr[3:];
         } elif instr.startswith('// div2') {
             instr = instr[3:];
-            if (instr[5] == instr[8]) {
+            if instr[5] == instr[8] {
                 instr = 'div2_inplace' + instr[4:];
             }
         } elif instr.startswith('neg') {
-            if (instr[4] == instr[7]) {
+            if instr[4] == instr[7] {
                 instr = 'neg_inplace' + instr[3:];
             }
         } elif instr.startswith('add') {
-            if (instr[7] == instr[10]) {
+            if instr[7] == instr[10] {
                 instr = 'add_twice' + instr[3:];
-            } elif (instr[4] == instr[10]) {
+            } elif instr[4] == instr[10] {
                 instr = instr[:7] + instr[10] + instr[8:10] + instr[7] + instr[11:];
             }
         } elif instr.startswith('sub') {
-            if (instr[4] == instr[10]) {
+            if instr[4] == instr[10] {
                 instr = 'sub_inplace' + instr[3:];
             }
         }
-        outputProgram.append(instr);
+        output_program.append(instr);
     }
-    return outputProgram;
+    return output_program;
 }
```

### 313569 `_extract_url_and_sha_from_deps_entry` — KEPT
```diff
--- floor
+++ idiomatic
@@ -1,10 +1,8 @@
 """Split a DEPS file entry into a URL and git sha."""
-def _extract_url_and_sha_from_deps_entry(`entry: Any) -> object {
-    assert (('url' in `entry) and ('rev' in `entry)) , (
-        'Unexpected format: %s' % `entry
-    );
-    url = `entry['url'];
-    sha = `entry['rev'];
+def _extract_url_and_sha_from_deps_entry(deps_entry: dict[str, str]) -> tuple[str, str] {
+    assert 'url' in deps_entry and 'rev' in deps_entry, f"Unexpected format: {deps_entry}";
+    url = deps_entry['url'];
+    sha = deps_entry['rev'];
     if url.endswith('.git') {
         url = url[:-len('.git')];
     }
```

### 147075 `_isIPv4Addr` — KEPT
```diff
--- floor
+++ idiomatic
@@ -1,52 +1,18 @@
-"""Confirm whether the specified address is an IPv4 address.
-
-    :param str strIPv4Addr: IPv4 address string.
-    :return: True when the specified address is an IPv4 address.
-    :rtype: bool
-
-    Example::
-
-        strIPv4Addr        Return
-        -------------------------
-        '192.0.2.1'   -> True
-        '192.0.2'     -> False
-        '192.0.2.256' -> False
-        '192.0.2.-1'  -> False
-        '192.0..1'    -> False
-        '192.0.a.1'   -> False
-
-    Test:
-        >>> _isIPv4Addr('192.0.2.1')
-        True
-        >>> _isIPv4Addr('192.0.2')
-        False
-        >>> _isIPv4Addr('192.0.2.256')
-        False
-        >>> _isIPv4Addr('192.0.2.-1')
-        False
-        >>> _isIPv4Addr('192.0..1')
-        False
-        >>> _isIPv4Addr('192.0.a.1')
-        False
-    """
-def _isIPv4Addr(strIPv4Addr: Any) -> object {
-    listStrIPv4Octet = strIPv4Addr.split('.');
-    if (len(listStrIPv4Octet) != 4) {
+"""Confirm whether the specified address is an IPv4 address."""
+def _isIPv4Addr(address: str) -> bool {
+    parts = address.split('.');
+    if len(parts) != 4 {
         return False;
     }
-    for i in range(4) {
-        strOctet = ("00" + listStrIPv4Octet[i])[-3:];
-        c1 = strOctet[0:1];
-        c2 = strOctet[1:2];
-        c3 = strOctet[2:3];
-        if (
-            ((c1 < '0') or (c1 > '9'))
-            or ((c2 < '0') or (c2 > '9'))
-            or ((c3 < '0') or (c3 > '9'))
-        ) {
+    for octet in parts {
+        s = ("00" + octet)[-3:];
+        c1 = s[0:1];
+        c2 = s[1:2];
+        c3 = s[2:3];
+        if (c1 < '0' or c1 > '9') or (c2 < '0' or c2 > '9') or (c3 < '0' or c3 > '9') {
             return False;
         }
-        if (int(strOctet, 10) >= 256) {
+        if int(s, 10) >= 256 {
             return False;
         }
     }
```

