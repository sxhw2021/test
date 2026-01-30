@echo off
chcp 65001 >nul
title Salt Player Lyric Adapter - 智能构建工具
setlocal enabledelayedexpansion

echo.
echo ========================================
echo   Salt Player Lyric Adapter 构建工具
echo ========================================
echo.

REM 检查当前目录
if not exist "settings.gradle.kts" (
    echo [错误] 请在项目根目录运行此脚本！
    echo 当前目录: %CD%
    echo.
    echo 请按以下步骤操作:
    echo 1. 打开文件资源管理器
    echo 2. 进入 C:\SaltPlayerLyricAdapter
    echo 3. 双击运行 build.bat
    echo.
    pause
    exit /b 1
)

REM 检查Java
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo [警告] 未检测到Java！
    echo.
    echo 请安装Java JDK 17:
    echo https://adoptium.net/temurin/releases/?version=17
    echo.
    pause
    exit /b 1
)

echo [✓] Java环境检测通过

REM 检查Gradle Wrapper
if not exist "gradlew.bat" (
    echo.
    echo [警告] 缺少Gradle Wrapper文件！
    echo.
    echo 请选择操作:
    echo [1] 尝试创建Gradle Wrapper（需要安装gradle）
    echo [2] 查看手动构建指南
    echo [3] 退出
    echo.
    set /p wrapper_choice=请选择 (1-3): 
    
    if "!wrapper_choice!"=="1" goto create_wrapper
    if "!wrapper_choice!"=="2" goto show_guide
    if "!wrapper_choice!"=="3" exit /b 0
    goto menu
)

echo [✓] Gradle Wrapper检测通过

:menu
echo.
echo ========================================
echo 请选择操作:
echo ========================================
echo.
echo  [1] 构建Debug APK (推荐测试用)
echo  [2] 构建Release APK
echo  [3] 清理构建缓存
echo  [4] 安装到设备 (需要ADB)
echo  [5] 查看构建输出
echo  [6] 打开Android Studio
echo  [7] 查看手动构建指南
echo  [8] 检查环境配置
echo  [9] 退出
echo.
set /p choice=请输入选项 (1-9): 

if "%choice%"=="1" goto build_debug
if "%choice%"=="2" goto build_release
if "%choice%"=="3" goto clean
if "%choice%"=="4" goto install
if "%choice%"=="5" goto output
if "%choice%"=="6" goto open_studio
if "%choice%"=="7" goto show_guide
if "%choice%"=="8" goto check_env
if "%choice%"=="9" goto end
cls
goto menu

:create_wrapper
echo.
echo 正在尝试创建Gradle Wrapper...
gradle wrapper --gradle-version 8.7 >nul 2>&1
if %errorlevel% equ 0 (
    echo [✓] Gradle Wrapper创建成功！
    echo 请重新运行此脚本。
) else (
    echo [✗] 创建失败，请手动安装Gradle或查看手动构建指南
    echo.
    start 手动构建指南.md
)
pause
goto menu

:show_guide
echo.
echo 正在打开手动构建指南...
if exist "手动构建指南.md" (
    start 手动构建指南.md
) else (
    echo [错误] 找不到手动构建指南.md
)
pause
goto menu

:build_debug
echo.
echo ========================================
echo [1/3] 正在构建Debug APK...
echo ========================================
echo.
call gradlew.bat :app:assembleDebug --console=plain
if %errorlevel% neq 0 (
    echo.
    echo [错误] 构建失败！
    echo.
    echo 可能的原因:
    echo 1. 未安装Android SDK
    echo 2. 未配置ANDROID_HOME环境变量
    echo 3. 网络问题无法下载依赖
    echo.
    echo 建议解决方案:
    echo - 安装Android Studio: https://developer.android.com/studio
    echo - 或查看手动构建指南.md
    echo.
    pause
    goto menu
)
echo.
echo ========================================
echo [✓] 构建成功！
echo ========================================
echo.
echo APK位置: app\build\outputs\apk\debug\app-debug.apk
if exist "app\build\outputs\apk\debug\app-debug.apk" (
    for %%F in ("app\build\outputs\apk\debug\app-debug.apk") do (
        echo 文件大小: %%~zF 字节
    )
)
echo.
pause
goto menu

:build_release
echo.
echo ========================================
echo [1/3] 正在构建Release APK...
echo ========================================
echo.
call gradlew.bat :app:assembleRelease --console=plain
if %errorlevel% neq 0 (
    echo.
    echo [错误] 构建失败！
    pause
    goto menu
)
echo.
echo [2/3] 构建完成！
echo [3/3] APK位置: app\build\outputs\apk\release\app-release.apk
echo.
pause
goto menu

:clean
echo.
echo 正在清理构建缓存...
call gradlew.bat clean --console=plain
if %errorlevel% equ 0 (
    echo [✓] 清理完成！
) else (
    echo [✗] 清理失败
)
pause
goto menu

:install
echo.
set apk_path=app\build\outputs\apk\debug\app-debug.apk
if not exist "%apk_path%" (
    echo [错误] 找不到APK文件！
    echo 预期路径: %apk_path%
    echo.
    echo 请先构建Debug版本 (选项1)
    pause
    goto menu
)

echo 正在检查ADB...
adb devices >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未检测到ADB！
    echo.
    echo 请检查:
    echo 1. 是否安装Android SDK Platform Tools
    echo 2. 是否将 platform-tools 添加到PATH
    echo 3. 手机是否连接并启用USB调试
    echo.
    pause
    goto menu
)

echo.
echo 已连接的设备:
adb devices
echo.
echo 正在安装APK...
adb install -r "%apk_path%"
if %errorlevel% equ 0 (
    echo.
    echo [✓] 安装成功！
    echo.
    echo 下一步:
    echo 1. 打开LSPosed管理器
    echo 2. 启用"Salt Player Lyric Adapter"模块
    echo 3. 作用域勾选 com.salt.music
    echo 4. 重启系统界面
) else (
    echo.
    echo [✗] 安装失败！
    echo.
    echo 常见原因:
    echo - 设备未连接
    echo - 未启用USB调试
    echo - 已安装签名冲突的版本
)
pause
goto menu

:output
echo.
if exist "app\build\outputs\apk" (
    echo 正在打开构建输出目录...
    start app\build\outputs\apk
) else (
    echo [错误] 构建输出目录不存在！
    echo 请先构建项目 (选项1)
)
pause
goto menu

:open_studio
echo.
echo 正在查找Android Studio...

REM 常见安装路径
set "studio_paths=C:\Program Files\Android\Android Studio\bin\studio64.exe"
set "studio_paths=!studio_paths%;C:\Program Files (x86)\Android\Android Studio\bin\studio64.exe"
set "studio_paths=!studio_paths%;%USERPROFILE%\AppData\Local\Android\Android Studio\bin\studio64.exe"

for %%i in (!studio_paths!) do (
    if exist "%%i" (
        echo [✓] 找到Android Studio: %%i
        echo 正在打开项目...
        start "" "%%i" "%CD%"
        pause
        goto menu
    )
)

echo [✗] 未找到Android Studio
echo.
echo 请手动打开Android Studio并导入项目:
echo %CD%
echo.
echo 或从以下地址下载:
echo https://developer.android.com/studio
pause
goto menu

:check_env
echo.
echo ========================================
echo 环境配置检查
echo ========================================
echo.

REM 检查Java
echo [Java]
java -version 2>&1 | findstr "version" | findstr "17" >nul
if %errorlevel% equ 0 (
    echo [✓] Java 17 已安装
) else (
    java -version 2>&1 | findstr "version"
    echo [?] 请确保是Java 17
)
echo.

REM 检查Android SDK
echo [Android SDK]
if defined ANDROID_HOME (
    echo [✓] ANDROID_HOME = %ANDROID_HOME%
    if exist "%ANDROID_HOME%\platform-tools\adb.exe" (
        echo [✓] ADB已找到
    ) else (
        echo [✗] 未找到ADB
    )
) else (
    echo [✗] ANDROID_HOME 未设置
    echo   请设置环境变量指向Android SDK路径
)
echo.

REM 检查Gradle
echo [Gradle]
if exist "gradlew.bat" (
    echo [✓] Gradle Wrapper已配置
) else (
    echo [✗] 缺少Gradle Wrapper
)
gradle -v >nul 2>&1
if %errorlevel% equ 0 (
    echo [✓] 全局Gradle已安装
    gradle -v 2>&1 | findstr "Gradle"
)
echo.

REM 检查项目结构
echo [项目结构]
if exist "settings.gradle.kts" echo [✓] settings.gradle.kts
if exist "build.gradle.kts" echo [✓] build.gradle.kts
if exist "app\build.gradle.kts" echo [✓] app\build.gradle.kts
echo.

pause
goto menu

:end
echo.
echo 感谢使用Salt Player Lyric Adapter构建工具！
echo.
timeout /t 2 >nul
exit /b 0
