import asyncio
import sys
import os
sys.path.append(os.path.dirname(__file__))

from main import main

async def test_main():
    try:
        await main()
        print("Main function executed successfully")
    except Exception as e:
        print(f"Error in main: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_main())