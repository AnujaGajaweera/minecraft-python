import math

class ClippingHelperFaces:

    def __init__(self, x, y, z, yaw, pitch):
        self.__posX = x
        self.__posY = y
        self.__posZ = z
        self.__posXPlus = math.sin(yaw / 180.0 * math.pi) * math.cos(pitch / 180.0 * math.pi)
        self.__posYPlus = -math.sin(pitch / 180.0 * math.pi)
        self.__posZPlus = -math.cos(yaw / 180.0 * math.pi) * math.cos(pitch / 180.0 * math.pi)
        self.__clippingBoundingBox = self.__posX * self.__posXPlus + self.__posY * \
                                     self.__posYPlus + self.__posZ * self.__posZPlus

    def isBoundingBoxInFrustum(self, x, y, z, minAxis):
        return x * self.__posXPlus + y * self.__posYPlus + z * \
               self.__posZPlus > self.__clippingBoundingBox - minAxis

    def isBoundingBoxFullyInFrustum(self, x0, y0, z0, x1, y1, z1):
        return (x0 * self.__posXPlus + y0 * self.__posYPlus + z0 * self.__posZPlus > self.__clippingBoundingBox or
                x1 * self.__posXPlus + y0 * self.__posYPlus + z0 * self.__posZPlus > self.__clippingBoundingBox or
                x0 * self.__posXPlus + y1 * self.__posYPlus + z0 * self.__posZPlus > self.__clippingBoundingBox or
                x1 * self.__posXPlus + y1 * self.__posYPlus + z0 * self.__posZPlus > self.__clippingBoundingBox or
                x0 * self.__posXPlus + y0 * self.__posYPlus + z1 * self.__posZPlus > self.__clippingBoundingBox or
                x1 * self.__posXPlus + y0 * self.__posYPlus + z1 * self.__posZPlus > self.__clippingBoundingBox or
                x0 * self.__posXPlus + y1 * self.__posYPlus + z1 * self.__posZPlus > self.__clippingBoundingBox or
                x1 * self.__posXPlus + y1 * self.__posYPlus + z1 * self.__posZPlus > self.__clippingBoundingBox)
