"""Urgent or normal action item card for the dashboard."""

import from "lucide-react" { AlertCircle, CheckCircle2 }

def:pub ActionItem(props: dict) -> JsxElement {
    text = props.get("text", "");
    index = props.get("index", 0);
    urgent = props.get("urgent", False);

    outer_cls = f"flex items-start gap-3 p-4 rounded-xl border {'bg-orange-50 border-orange-200'
        if urgent
        else 'bg-white border-warm-200'}";
    icon_cls = f"mt-0.5 flex-shrink-0 {'text-orange-500'
        if urgent
        else 'text-primary-400'}";
    text_cls = f"text-sm leading-relaxed {'text-orange-900'
        if urgent
        else 'text-warm-800'}";

    return
        <div className={outer_cls}>
            <div className={icon_cls}>
                {<AlertCircle className="w-5 h-5"/>
                    if urgent
                    else <CheckCircle2 className="w-5 h-5"/>}
            </div>
            <div>
                <div className="text-xs font-medium text-warm-500 mb-0.5">
                    Action {index + 1}
                </div>
                <p className={text_cls}>{text}</p>
            </div>
        </div>;
}
