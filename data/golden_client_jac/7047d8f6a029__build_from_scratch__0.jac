"""Single ingredient row -- presentational."""

sv import from ..main { ShoppingItem }

def:pub IngredientItem(ing: ShoppingItem) -> JsxElement {
    return
        <div class="ingredient-item">
            <div class="ing-info">
                <span class="ing-name">{ing.name}</span>
                <span class="ing-qty">{ing.quantity} {ing.unit}</span>
            </div>
            <span class="ing-cost">{ing.cost}</span>
        </div>;
}
