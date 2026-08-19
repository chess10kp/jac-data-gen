cl {
    def:pub Box(as_: str = "div", children: any = None) -> JsxElement {
        return <@as_ className="box">{children}</@as_>;
    }

    def:pub Demo() -> JsxElement {
        return <>
            <Box as_="article">Inside an article element</Box>
            <Box as_="section">Inside a section element</Box>
        </>;
    }
}
