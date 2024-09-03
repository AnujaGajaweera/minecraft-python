from mc.net.minecraft.client.render.entity.RenderLiving import RenderLiving
from mc.net.minecraft.client.model.ModelBiped import ModelBiped

class RenderPlayer(RenderLiving):

    def __init__(self):
        super().__init__(ModelBiped(), 0.5)
        ModelBiped(1.0)
        ModelBiped(0.5)
        self.__modelBipedMain = self._mainModel

    def drawFirstPersonHand(self):
        self.__modelBipedMain.bipedRightArm.render(1.0)

    def _shouldRenderPass(self, entity, i):
        return False
