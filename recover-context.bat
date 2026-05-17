@echo off
REM Auto-recovery context script for TFG-LAIA-Backend
REM This script ensures any tool can recover full context from engram

setlocal enabledelayedexpansion

echo.
echo ========================================
echo TFG-LAIA-Backend Context Recovery
echo ========================================
echo.

REM Activate venv
call d:\TFG\.venv\Scripts\activate.bat

REM Recover context from engram
echo [1/3] Recovering context from engram...
python -c "from mcp_engram_mem_context import get_context; print(get_context('TFG-LAIA-Backend'))" >nul 2>&1

if errorlevel 1 (
    echo WARNING: Could not auto-load engram. Manual recovery available:
    echo   - Use: engram.exe retrieve --project TFG-LAIA-Backend
    echo   - Or read: d:\TFG\.instructions.md
) else (
    echo [OK] Context loaded from engram
)

REM Check current file state
echo [2/3] Verifying file state...
if exist "d:\TFG\Backend\backend\models.py" (
    echo [OK] backend/models.py exists
) else (
    echo [WARN] backend/models.py NOT found
)

REM Ready for work
echo [3/3] Environment ready
echo.
echo Project: TFG-LAIA-Backend
echo Path: d:\TFG\Backend
echo Server: http://localhost:8005
echo.
echo Ready to proceed. Use --instructions flag to see context.
echo.
