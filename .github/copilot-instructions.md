# POS Kosovo - Workspace Instructions

## Project Overview
Complete Point of Sale system for Kosovo retail/wholesale businesses with fiscal printer integration.

## Technology Stack
- **Framework**: C# WPF (Windows Presentation Foundation)
- **Database**: SQLite with Entity Framework Core
- **Language**: Albanian (Kosovo dialect)
- **Fiscal Printer**: FP700+ with F-Link KS integration
- **Standard Printer**: Epson TM series support

## Project Structure
- `KosovaPOS.sln` - Main solution file
- `KosovaPOS/` - Main WPF application
  - `Windows/` - All application windows (CashRegister, Articles, Sales, etc.)
  - `Models/` - Database models and entities
  - `Services/` - Business logic and printer services
  - `Resources/` - Albanian language resources
  - `Database/` - SQLite database and migrations
- `KosovaPOS.Core/` - Shared business logic library
- `KosovaPOS.FiscalPrinter/` - Fiscal printer integration library

## Development Guidelines
1. All UI text must be in Albanian language
2. Follow Kosovo tax regulations (VAT, fiscal reporting)
3. Generate fiscal files at C:\Temp\ directory
4. Implement all keyboard shortcuts (F5, F6, F10, Ctrl+Z, Alt+O, etc.)
5. Use barcode scanning for product input
6. Support both fiscal and non-fiscal receipt printing

## Kosovo Tax System
- Standard VAT: 18%
- Reduced VAT: 8%
- Fiscal reports: Z-Report (daily), X-Report (current session)
- Receipt format: S,1,______,_,__;Product;Qty;Price;Tax;...

## Keyboard Shortcuts
- F5: Print Receipt
- F6: Copy
- F3: Clear Row
- F10: Discard Receipt
- Ctrl+Z: Z-Report
- Ctrl+X: X-Report
- Ctrl+S: Sold Articles
- Alt+F4: Close Window
- Alt+O: Add New Article
- Alt+N: Edit Article
- Alt+F: Delete Article
- Alt+R: Refresh
- Alt+E: Excel Export
- Alt+B: Print Barcode
- Alt+M: Close

## Completed Steps
✓ Created workspace instructions file

## Next Steps
1. Scaffold C# WPF project structure
2. Setup SQLite database with Entity Framework
3. Implement main cash register window
4. Add fiscal printer integration
5. Create articles management window
6. Implement all menu modules
7. Add Albanian localization
8. Test with sample data
