@echo off
chcp 65001 >nul
title Salt Player Lyric Adapter - 构建脚本
echo.
echo ========================================
echo   Salt Player Lyric Adapter 构建工具
echo ========================================
echo.

REM 检查Gradle Wrapper
if not exist "gradlew" (
    echo [错误] 找不到gradlew文件，请确保在项目根目录
    pause
    exit /b 1
)

:menu
echo 请选择操作:
echo.
echo  [1] 构建Debug APK (推荐测试用)
echo  [2] 构建Release APK
  echo  [3] 清理构建缓存
echo  [4] 安装到设备 (需要ADB)
echo  [5] 查看构建输出
echo  [6] 退出
echo.
set /p choice=请输入选项 (1-6): 

if "%choice%"=="1" goto build_debug
if "%choice%"=="2" goto build_release
if "%choice%"=="3" goto clean
if "%choice%"=="4" goto install
if "%choice%"=="5" goto output
if "%choice%"=="6" goto end
goto menu

:build_debug
echo.
echo [1/3] 正在构建Debug APK...
call gradlew.bat :app:assembleDebug
if %errorlevel% neq 0 (
    echo [错误] 构建失败，请检查错误信息
    pause
    goto menu
)
echo [2/3] 构建完成！
echo [3/3] APK位置: app\build\outputs\apk\debug\app-debug.apk
echo.
pause
goto menu

:build_release
echo.
echo [1/3] 正在构建Release APK...
call gradlew.bat :app:assembleRelease
if %errorlevel% neq 0 (
    echo [错误] 构建失败，请检查错误信息
    pause
    goto menu
)
echo [2/3] 构建完成！
echo [3/3] APK位置: app\build\outputs\apk\release\app-release.apk
echo.
pause
goto menu

:clean
echo.
echo 正在清理构建缓存...
call gradlew.bat clean
echo 清理完成！
echo.
pause
goto menu

:install
echo.
set apk_path=app\build\outputs\apk\debug\app-debug.apk
if not exist "%apk_path%" (
    echo [错误] 找不到APK文件，请先构建Debug版本
    echo 预期路径: %apk_path%
    pause
    goto menu
)
echo 正在安装APK到设备...
adb install -r "%apk_path%"
if %errorlevel% neq 0 (
    echo [错误] 安装失败，请检查:
    echo   1. 设备是否连接 (adb devices)
    echo   2. 是否启用USB调试
    echo   3. 是否有安装权限
)
pause
goto menu

:output
echo.
echo 打开构建输出目录...
if exist "app\build\outputs\apk" (
    start app\build\outputs\apk
) else (
    echo [错误] 构建输出目录不存在，请先构建项目
)
pause
goto menu

:end
echo.
echo 感谢使用！
timeout /t 2 >nul
exit
