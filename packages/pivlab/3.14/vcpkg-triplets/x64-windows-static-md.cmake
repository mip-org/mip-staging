# Package-local overlay triplet: the channel-shared
# mip_channel_tools/vcpkg-triplets/x64-windows-static-md.cmake plus one CXX
# define. Passed via --overlay-triplets in mip.yaml's windows setup command,
# which takes precedence over the channel dir in VCPKG_OVERLAY_TRIPLETS.
#
# _DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR: MSVC >= 14.40 (VS 17.10) makes
# std::mutex's constructor constexpr. Objects built that way fail at DLL
# initialization ("DLL initialization routine failed") when the process
# already holds a pre-14.40 msvcp140.dll -- and MATLAB preloads its own,
# which on the R2023a-era test MATLAB is older. OpenCV core/imgproc hold
# static mutexes, so the flag must be active when vcpkg compiles OpenCV
# itself; it makes the constructor run at dynamic init, compatible with any
# msvcp140. Candidate for promotion to the channel-shared triplet.
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_BUILD_TYPE release)
set(VCPKG_C_FLAGS "-D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR")
set(VCPKG_CXX_FLAGS "-D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR")
