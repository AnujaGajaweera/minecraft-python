from mc.net.minecraft.game.item.Item import Item

class ItemArmor(Item):

    def __init__(self, items, itemId, armorLevel, armorType):
        super().__init__(items, itemId)
