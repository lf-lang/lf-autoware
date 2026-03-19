enable_language(CXX)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-write-strings -O2")

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_components REQUIRED)
find_package(rcutils)
find_package(rmw REQUIRED)

ament_target_dependencies(${LF_MAIN_TARGET} PUBLIC rclcpp rmw)
add_compile_definitions(LF_SOURCE_DIRECTORY="/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src")
add_compile_definitions(LF_PACKAGE_DIRECTORY="/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/.")
add_compile_definitions(LF_SOURCE_GEN_DIRECTORY="/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/./fed-gen/AutowareFederated/src-gen")
add_compile_definitions(LF_FILE_SEPARATOR="/")
