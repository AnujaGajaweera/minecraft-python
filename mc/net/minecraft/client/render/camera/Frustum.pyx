# cython: language_level=3

from libc.math cimport cos, sin, pi

from mc.net.minecraft.client.render.camera.ClippingHelperFaces import ClippingHelperFaces
from mc.net.minecraft.game.physics.AxisAlignedBB cimport AxisAlignedBB

cdef class Frustum:

    def __init__(self, entity, distance, a):
        cdef float yaw = entity.prevRotationYaw + (entity.rotationYaw - entity.prevRotationYaw) * a
        cdef float pitch = entity.prevRotationPitch + (entity.rotationPitch - entity.prevRotationPitch) * a
        cdef float xd = entity.lastTickPosX + (entity.posX - entity.lastTickPosX) * a
        cdef float yd = entity.lastTickPosY + (entity.posY - entity.lastTickPosY) * a
        cdef float zd = entity.lastTickPosZ + (entity.posZ - entity.lastTickPosZ) * a
        cdef float forward = sin(yaw / 180.0 * pi) * cos(pitch / 180.0 * pi)
        cdef float left = -cos(yaw / 180.0 * pi) * cos(pitch / 180.0 * pi)
        cdef float up = -sin(pitch / 180.0 * pi)
        self.__clippingHelper = [
            ClippingHelperFaces(xd, yd, zd, yaw, pitch),
            ClippingHelperFaces(xd, yd, zd, yaw + 30.0, pitch),
            ClippingHelperFaces(xd, yd, zd, yaw - 30.0, pitch),
            ClippingHelperFaces(xd, yd, zd, yaw, pitch + 45.0),
            ClippingHelperFaces(xd, yd, zd, yaw, pitch - 45.0),
            ClippingHelperFaces(xd + forward * distance, yd + up * distance,
                                zd + left * distance, yaw + 180.0, -pitch)
        ]

    cpdef bint isVisible(self, AxisAlignedBB aabb):
        cdef float maxZ, maxY, maxX, minZ, minY, minX, xd, yd, zd, x, y, z, minAxis

        maxZ = aabb.maxZ
        maxY = aabb.maxY
        maxX = aabb.maxX
        minZ = aabb.minZ
        minY = aabb.minY
        minX = aabb.minX
        xd = (maxX - minX) / 2.0
        yd = (maxY - minY) / 2.0
        zd = (maxZ - minZ) / 2.0
        x = minX + xd
        y = minY + yd
        z = minZ + zd
        if xd > yd:
            if xd <= zd:
                minAxis = xd
            else:
                minAxis = yd
        elif yd > zd:
            minAxis = yd
        else:
            minAxis = zd

        minAxis *= 1.5
        if not self.__clippingHelper[0].isBoundingBoxInFrustum(x, y, z, minAxis):
            return False
        elif not self.__clippingHelper[1].isBoundingBoxInFrustum(x, y, z, minAxis):
            return False
        elif not self.__clippingHelper[2].isBoundingBoxInFrustum(x, y, z, minAxis):
            return False
        elif not self.__clippingHelper[3].isBoundingBoxInFrustum(x, y, z, minAxis):
            return False
        elif not self.__clippingHelper[4].isBoundingBoxInFrustum(x, y, z, minAxis):
            return False
        elif not self.__clippingHelper[5].isBoundingBoxInFrustum(x, y, z, minAxis):
            return False
        elif not self.__clippingHelper[0].isBoundingBoxFullyInFrustum(minX, minY, minZ,
                                                                      maxX, maxY, maxZ):
            return False
        elif not self.__clippingHelper[1].isBoundingBoxFullyInFrustum(minX, minY, minZ,
                                                                      maxX, maxY, maxZ):
            return False
        elif not self.__clippingHelper[2].isBoundingBoxFullyInFrustum(minX, minY, minZ,
                                                                      maxX, maxY, maxZ):
            return False
        elif not self.__clippingHelper[3].isBoundingBoxFullyInFrustum(minX, minY, minZ,
                                                                      maxX, maxY, maxZ):
            return False
        elif not self.__clippingHelper[4].isBoundingBoxFullyInFrustum(minX, minY, minZ,
                                                                      maxX, maxY, maxZ):
            return False
        else:
            return self.__clippingHelper[5].isBoundingBoxFullyInFrustum(minX, minY, minZ,
                                                                        maxX, maxY, maxZ)

