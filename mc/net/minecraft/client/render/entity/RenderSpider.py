from mc.net.minecraft.client.render.entity.RenderLiving import RenderLiving
from mc.net.minecraft.client.model.ModelSpider import ModelSpider

class RenderSpider(RenderLiving):

    def __init__(self):
        super().__init__(ModelSpider(), 1.0)

    def _getDeathMaxRotation(self, entity):
        return 180.0
