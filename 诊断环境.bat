@echo off
chcp 65001 >nul
title Salt Player Lyric Adapter - 环境诊断工具
echo.
echo ========================================
echo     环境诊断工具
echo ========================================
echo.

set "ERROR_COUNT=0"
set "WARNING_COUNT=0"

REM 检查1: 当前目录
echo [检查1/8] 项目目录...
if exist "settings.gradle.kts" (
    echo   [✓] 已在项目根目录
echo   路径: %CD%
) else (
    echo   [✗] 不在项目根目录！
    echo   当前: %CD%
    echo   请进入 C:\SaltPlayerLyricAdapter 目录
    set /a ERROR_COUNT+=1
)
echo.

REM 检查2: Java
echo [检查2/8] Java环境...
java -version >nul 2>&1
if %errorlevel% equ 0 (
    echo   [✓] Java已安装
    for /f "tokens=3" %%g in ('java -version 2^>^&1 ^| findstr /i "version"') do (
        echo   版本: %%g
    )
) else (
    echo   [✗] Java未安装！
    echo   请下载: https://adoptium.net/temurin/releases/?version=17
    set /a ERROR_COUNT+=1
)
echo.

REM 检查3: JAVA_HOME
echo [检查3/8] JAVA_HOME环境变量...
if defined JAVA_HOME (
    echo   [✓] JAVA_HOME = %JAVA_HOME%
    if exist "%JAVA_HOME%\bin\java.exe" (
        echo   [✓] 路径有效
    ) else (
        echo   [✗] 路径无效！
        set /a WARNING_COUNT+=1
    )
) else (
    echo   [?] JAVA_HOME 未设置（可能不是必须的）
)
echo.

REM 检查4: Android SDK
echo [检查4/8] Android SDK...
if defined ANDROID_HOME (
    echo   [✓] ANDROID_HOME = %ANDROID_HOME%
    if exist "%ANDROID_HOME%" (
        echo   [✓] SDK目录存在
        if exist "%ANDROID_HOME%\platform-tools\adb.exe" (
            echo   [✓] ADB工具存在
        ) else (
            echo   [?] 未找到ADB
        )
    ) else (
        echo   [✗] SDK目录不存在！
        set /a WARNING_COUNT+=1
    )
) else (
    echo   [?] ANDROID_HOME 未设置
    echo   如果需要命令行构建，请设置此变量
)
echo.

REM 检查5: Gradle Wrapper
echo [检查5/8] Gradle Wrapper...
if exist "gradlew.bat" (
    echo   [✓] gradlew.bat 存在
) else (
    echo   [✗] 缺少 gradlew.bat！
    echo   项目需要Gradle Wrapper才能构建
    set /a ERROR_COUNT+=1
)

if exist "gradle\wrapper\gradle-wrapper.properties" (
    echo   [✓] gradle-wrapper.properties 存在
) else (
    echo   [?] 缺少 gradle-wrapper.properties
    set /a WARNING_COUNT+=1
)
echo.

REM 检查6: 项目文件
echo [检查6/8] 项目文件完整性...
set "MISSING_FILES=0"

if not exist "build.gradle.kts" (
    echo   [✗] 缺少 build.gradle.kts
    set /a MISSING_FILES+=1
) else (
    echo   [✓] build.gradle.kts
)

if not exist "app\build.gradle.kts" (
    echo   [✗] 缺少 app\build.gradle.kts
    set /a MISSING_FILES+=1
) else (
    echo   [✓] app\build.gradle.kts
)

if not exist "settings.gradle.kts" (
    echo   [✗] 缺少 settings.gradle.kts
    set /a MISSING_FILES+=1
) else (
    echo   [✓] settings.gradle.kts
)

if not exist "gradle\libs\versions.toml" (
    echo   [✗] 缺少 gradle\libs\versions.toml
    set /a MISSING_FILES+=1
) else (
    echo   [✓] gradle\libs\versions.toml
)

if %MISSING_FILES% gtr 0 (
    set /a ERROR_COUNT+=%MISSING_FILES%
)
echo.

REM 检查7: 源代码文件
echo [检查7/8] 源代码文件...
if exist "app\src\main\java\io\github\proify\saltadapter\SaltPlayerHook.kt" (
    echo   [✓] SaltPlayerHook.kt
) else (
    echo   [✗] 缺少 SaltPlayerHook.kt
    set /a WARNING_COUNT+=1
)

if exist "app\src\main\java\io\github\proify\saltadapter\SaltLyricProvider.kt" (
    echo   [✓] SaltLyricProvider.kt
) else (
    echo   [✗] 缺少 SaltLyricProvider.kt
    set /a WARNING_COUNT+=1
)
echo.

REM 检查8: 网络和权限
echo [检查8/8] 网络和权限...
echo   [i] 项目路径: %CD%
echo   [i] 路径长度: 未检查

if exist "C:\Program Files\Android\Android Studio" (
    echo   [✓] 检测到Android Studio
) else if exist "%USERPROFILE%\AppData\Local\Android\Android Studio" (
    echo   [✓] 检测到Android Studio (用户目录)
) else (
    echo   [?] 未检测到Android Studio
    echo   建议安装以简化构建: https://developer.android.com/studio
)
echo.

REM 诊断结果
echo ========================================
echo           诊断结果
echo ========================================
echo.

if %ERROR_COUNT% equ 0 (
    if %WARNING_COUNT% equ 0 (
        echo [✓] 所有检查通过！
        echo.
        echo 你现在可以运行 build_simple.bat 来构建APK了。
    ) else (
        echo [!] 发现 %WARNING_COUNT% 个警告
        echo.
        echo 项目可以构建，但可能需要注意上述警告。
    )
) else (
    echo [✗] 发现 %ERROR_COUNT% 个错误，%WARNING_COUNT% 个警告
    echo.
    echo 请解决上述错误后再尝试构建。
    echo.
    echo 最简单的解决方案：
    echo 1. 安装Android Studio (自动配置所有环境)
    echo    https://developer.android.com/studio
    echo.
    echo 2. 或使用GitHub Actions自动构建
    echo    查看 紧急解决方案.md -^> 方案3
)

echo.
echo ========================================
echo.

if %ERROR_COUNT% gtr 0 (
    echo 按任意键查看解决方案...
    pause >nul
    
    echo.
    echo 解决方案：
    echo.
    echo 方案A - 安装Android Studio（推荐）:
    echo   1. 下载: https://developer.android.com/studio
    echo   2. 安装选择"Standard"
    echo   3. 重启后双击 build_simple.bat
    echo.
    echo 方案B - 手动配置:
    echo   1. 安装Java JDK 17
    echo   2. 设置JAVA_HOME环境变量
    echo   3. 安装Android SDK
    echo   4. 设置ANDROID_HOME环境变量
    echo.
    echo 方案C - GitHub Actions（无需本地环境）:
    echo   查看 紧急解决方案.md -^> 方案3
    echo.
)

pause
