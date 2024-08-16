# cython: language_level=3

from mc.net.minecraft.game.physics.AxisAlignedBB cimport AxisAlignedBB

cdef class Frustum:

    cdef:
        list __clippingHelper

    cpdef bint isVisible(self, AxisAlignedBB aabb)
