# These libm functions are known to fail under verrou due to range wrapping
__cos_fma       /lib64/libm-2.27.so
__dubsin_fma  /lib64/libm-2.27.so
__ieee754_acos_fma    /lib64/libm-2.27.so
__ieee754_atan2_fma   /lib64/libm-2.27.so
__sin_fma       /lib64/libm-2.27.so
__tan_fma       /lib64/libm-2.27.so
__atan_fma      /lib64/libm-2.27.so
sincos  /lib64/libm-2.27.so

# This should fail for the same reasons, but it seems we can get away without excluding it for now
# _ZN4Acts6detail13wrap_periodicIdEET_S2_S2_S2_   /root/acts-core/spack-build/Core/libActsCore.so

# These exclusions handle a numerical instability in the setup of SurfaceArrayCreatorTests
_ZN4Acts4Test26SurfaceArrayCreatorFixture17makeBarrelStaggerEiidddd     /root/acts-core/spack-build/Tests/Core/Tools/SurfaceArrayCreatorTests
_ZN4Acts4Test26SurfaceArrayCreatorFixture22fullPhiTestSurfacesBRLEmddddd        /root/acts-core/spack-build/Tests/Core/Tools/SurfaceArrayCreatorTests
_ZN4Acts4Test26SurfaceArrayCreatorFixture21fullPhiTestSurfacesECEmddddd /root/acts-core/spack-build/Tests/Core/Tools/SurfaceArrayCreatorTests

# These exclusions handle a false positive in the conversion of CylinderLayer to variant_data and back
_ZNK4Acts13CylinderLayer13toVariantDataB5cxx11Ev        /root/acts-core/spack-build/Core/libActsCore.so
_ZN4Acts13CylinderLayerC1ERKSt10shared_ptrIKN5Eigen9TransformIdLi3ELi2ELi0EEEERKS1_IKNS_14CylinderBoundsEESt10unique_ptrINS_12SurfaceArrayESt14default_deleteISF_EEdSE_INS_18ApproachDescriptorESG_ISJ_EENS_9LayerTypeE /root/acts-core/spack-build/Core/libActsCore.so
