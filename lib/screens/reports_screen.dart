import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Reports & Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Currently Under Development',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'We are working hard to bring you comprehensive\nreports and analytics features. Stay tuned!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Progress indicator
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '25%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.25,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Features coming soon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coming Soon:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem('📊 Sales Analytics'),
                    _buildFeatureItem('📈 Inventory Trends'),
                    _buildFeatureItem('🏆 Top Performing Products'),
                    _buildFeatureItem('📄 Export to PDF/Excel'),
                    _buildFeatureItem('🖨️ Print Reports'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            feature,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Previous commented code below for future reference:
//   State<ReportsScreen> createState() => _ReportsScreenState();
// }

// class _ReportsScreenState extends State<ReportsScreen> {
//   final DatabaseService _databaseService = DatabaseService();
//   String _selectedPeriod = 'Weekly';
//   bool _isLoading = true;

//   // Data variables
//   ReportSummary? _summary;
//   List<SalesData> _salesData = [];
//   List<CategoryData> _categoryData = [];
//   List<ProductPerformance> _topProducts = [];
//   List<ProductPerformance> _worstProducts = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadReportData();
//   }

//   Future<void> _loadReportData() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Generate dummy/mock data for demonstration
//       await _generateDummyData();
//       setState(() {
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading report data: $e')),
//         );
//       }
//     }
//   }

//   Future<void> _generateDummyData() async {
//     // Get real data from database
//     final products = await _databaseService.getAllProducts();
//     final lowStockProducts = await _databaseService.getLowStockProducts();

//     // Generate summary data
//     _summary = ReportSummary(
//       totalProductsSold: 45,
//       totalQuantitySold: 1248,
//       activeProducts: products.where((p) => p.quantity > 0).length,
//       lowStockItems: lowStockProducts.length,
//     );

//     // Generate sales over time data
//     _salesData = _generateSalesData();

//     // Generate category distribution data
//     _categoryData = _generateCategoryData();

//     // Generate product performance data
//     _generateProductPerformanceData();
//   }

//   List<SalesData> _generateSalesData() {
//     final now = DateTime.now();
//     final salesData = <SalesData>[];

//     switch (_selectedPeriod) {
//       case 'Daily':
//         for (int i = 6; i >= 0; i--) {
//           final date = now.subtract(Duration(days: i));
//           salesData.add(SalesData(
//             date: date,
//             quantity: 15 + (i * 5) + (i % 3 * 10),
//             period: DateFormat('MMM dd').format(date),
//           ));
//         }
//         break;
//       case 'Weekly':
//         for (int i = 11; i >= 0; i--) {
//           final date = now.subtract(Duration(days: i * 7));
//           salesData.add(SalesData(
//             date: date,
//             quantity: 80 + (i * 20) + (i % 4 * 30),
//             period: 'Week ${52 - i}',
//           ));
//         }
//         break;
//       case 'Monthly':
//         for (int i = 11; i >= 0; i--) {
//           final date = DateTime(now.year, now.month - i, 1);
//           salesData.add(SalesData(
//             date: date,
//             quantity: 300 + (i * 50) + (i % 3 * 100),
//             period: DateFormat('MMM').format(date),
//           ));
//         }
//         break;
//     }

//     return salesData;
//   }

//   List<CategoryData> _generateCategoryData() {
//     return [
//       CategoryData(category: 'Makina', quantity: 450, percentage: 45.0),
//       CategoryData(category: 'Steel', quantity: 350, percentage: 35.0),
//       CategoryData(category: 'Other', quantity: 200, percentage: 20.0),
//     ];
//   }

//   void _generateProductPerformanceData() {
//     _topProducts = [
//       ProductPerformance(
//           productName: 'Makina italy mab asii',
//           quantitySold: 156,
//           category: 'Steel',
//           revenue: 15600.0),
//       ProductPerformance(
//           productName: 'Steel 4c pss',
//           quantitySold: 134,
//           category: 'Steel',
//           revenue: 13400.0),
//       ProductPerformance(
//           productName: 'All dorman pss',
//           quantitySold: 98,
//           category: 'Makina',
//           revenue: 9800.0),
//       ProductPerformance(
//           productName: 'Keilon dorman pss',
//           quantitySold: 87,
//           category: 'Steel',
//           revenue: 8700.0),
//       ProductPerformance(
//           productName: 'Steel 4c black',
//           quantitySold: 76,
//           category: 'Other',
//           revenue: 7600.0),
//     ];

//     _worstProducts = [
//       ProductPerformance(
//           productName: 'Hapja dorman pss',
//           quantitySold: 12,
//           category: 'Other',
//           revenue: 1200.0),
//       ProductPerformance(
//           productName: 'Premium Steel Rod',
//           quantitySold: 8,
//           category: 'Steel',
//           revenue: 800.0),
//       ProductPerformance(
//           productName: 'Atar',
//           quantitySold: 15,
//           category: 'Other',
//           revenue: 1500.0),
//       ProductPerformance(
//           productName: 'Makina dorman pss',
//           quantitySold: 23,
//           category: 'Makina',
//           revenue: 2300.0),
//       ProductPerformance(
//           productName: 'Custom Part A',
//           quantitySold: 5,
//           category: 'Other',
//           revenue: 500.0),
//     ];
//   }

//   void _onPeriodChanged(String? newPeriod) {
//     if (newPeriod != null && newPeriod != _selectedPeriod) {
//       setState(() {
//         _selectedPeriod = newPeriod;
//       });
//       _loadReportData();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Reports & Analytics',
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       // Period Filter
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey[300]!),
//                           borderRadius: BorderRadius.circular(8),
//                           color: Colors.white,
//                         ),
//                         child: DropdownButton<String>(
//                           value: _selectedPeriod,
//                           icon: const Icon(Icons.calendar_today,
//                               color: Color(0xFF4A90E2)),
//                           underline: Container(),
//                           items: ['Daily', 'Weekly', 'Monthly']
//                               .map((String value) {
//                             return DropdownMenuItem<String>(
//                               value: value,
//                               child: Text(value),
//                             );
//                           }).toList(),
//                           onChanged: _onPeriodChanged,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 32),

//                   // Summary Cards
//                   _buildSummaryCards(),
//                   const SizedBox(height: 32),

//                   // Charts Row
//                   Row(
//                     children: [
//                       // Sales Over Time Chart
//                       Expanded(
//                         flex: 2,
//                         child: _buildSalesChart(),
//                       ),
//                       const SizedBox(width: 24),
//                       // Category Distribution Chart
//                       Expanded(
//                         flex: 1,
//                         child: _buildCategoryChart(),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 32),

//                   // Product Performance Tables
//                   _buildPerformanceTables(),
//                   const SizedBox(height: 32),

//                   // Export Options
//                   _buildExportOptions(),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildSummaryCards() {
//     if (_summary == null) return Container();

//     final cards = [
//       _SummaryCard(
//         title: 'Total Products Sold',
//         value: _summary!.totalProductsSold.toString(),
//         icon: Icons.shopping_cart,
//         color: Colors.blue,
//       ),
//       _SummaryCard(
//         title: 'Total Quantity Sold',
//         value: _summary!.totalQuantitySold.toString(),
//         icon: Icons.inventory,
//         color: Colors.green,
//       ),
//       _SummaryCard(
//         title: 'Active Products',
//         value: _summary!.activeProducts.toString(),
//         icon: Icons.check_circle,
//         color: Colors.orange,
//       ),
//       _SummaryCard(
//         title: 'Low Stock Items',
//         value: _summary!.lowStockItems.toString(),
//         icon: Icons.warning,
//         color: Colors.red,
//       ),
//     ];

//     return Row(
//       children: cards
//           .map((card) => Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.only(right: 16),
//                   child: card,
//                 ),
//               ))
//           .toList(),
//     );
//   }

//   Widget _buildSalesChart() {
//     return Container(
//       height: 400,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 8,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Sales Over Time ($_selectedPeriod)',
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 20),
//           Expanded(
//             child: SfCartesianChart(
//               primaryXAxis: const CategoryAxis(
//                 majorGridLines: MajorGridLines(width: 0),
//               ),
//               primaryYAxis: const NumericAxis(
//                 title: AxisTitle(text: 'Quantity Sold'),
//                 majorGridLines: MajorGridLines(width: 0.5),
//               ),
//               plotAreaBorderWidth: 0,
//               series: <CartesianSeries>[
//                 ColumnSeries<SalesData, String>(
//                   dataSource: _salesData,
//                   xValueMapper: (SalesData data, _) => data.period,
//                   yValueMapper: (SalesData data, _) => data.quantity,
//                   color: const Color(0xFF4A90E2),
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(4),
//                     topRight: Radius.circular(4),
//                   ),
//                 ),
//               ],
//               tooltipBehavior: TooltipBehavior(enable: true),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCategoryChart() {
//     return Container(
//       height: 400,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 8,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Category Distribution',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 20),
//           Expanded(
//             child: SfCircularChart(
//               legend: const Legend(
//                 isVisible: true,
//                 position: LegendPosition.bottom,
//               ),
//               series: <CircularSeries>[
//                 PieSeries<CategoryData, String>(
//                   dataSource: _categoryData,
//                   xValueMapper: (CategoryData data, _) => data.category,
//                   yValueMapper: (CategoryData data, _) => data.quantity,
//                   dataLabelMapper: (CategoryData data, _) =>
//                       '${data.percentage}%',
//                   dataLabelSettings: const DataLabelSettings(
//                     isVisible: true,
//                     labelPosition: ChartDataLabelPosition.outside,
//                   ),
//                   explode: true,
//                   explodeIndex: 0,
//                 ),
//               ],
//               tooltipBehavior: TooltipBehavior(enable: true),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPerformanceTables() {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Top Performing Products
//         Expanded(
//           child: _buildPerformanceTable(
//             'Top 5 Products Sold',
//             _topProducts,
//             Colors.green,
//           ),
//         ),
//         const SizedBox(width: 24),
//         // Worst Performing Products
//         Expanded(
//           child: _buildPerformanceTable(
//             'Least 5 Products Sold',
//             _worstProducts,
//             Colors.red,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPerformanceTable(
//       String title, List<ProductPerformance> products, Color accentColor) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 8,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 4,
//                 height: 20,
//                 decoration: BoxDecoration(
//                   color: accentColor,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           DataTable(
//             headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
//             columns: const [
//               DataColumn(
//                   label: Text('Product Name',
//                       style: TextStyle(fontWeight: FontWeight.w600))),
//               DataColumn(
//                   label: Text('Qty Sold',
//                       style: TextStyle(fontWeight: FontWeight.w600))),
//               DataColumn(
//                   label: Text('Category',
//                       style: TextStyle(fontWeight: FontWeight.w600))),
//             ],
//             rows: products
//                 .map((product) => DataRow(
//                       cells: [
//                         DataCell(
//                           SizedBox(
//                             width: 150,
//                             child: Text(
//                               product.productName,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ),
//                         DataCell(Text(product.quantitySold.toString())),
//                         DataCell(Text(product.category)),
//                       ],
//                     ))
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildExportOptions() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 8,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Export Options',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 20),
//           Row(
//             children: [
//               _buildExportButton(
//                 'Export as PDF',
//                 Icons.picture_as_pdf,
//                 Colors.red,
//                 () => _exportAsPDF(),
//               ),
//               const SizedBox(width: 16),
//               _buildExportButton(
//                 'Export as Excel',
//                 Icons.table_chart,
//                 Colors.green,
//                 () => _exportAsExcel(),
//               ),
//               const SizedBox(width: 16),
//               _buildExportButton(
//                 'Print Report',
//                 Icons.print,
//                 Colors.blue,
//                 () => _printReport(),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildExportButton(
//       String label, IconData icon, Color color, VoidCallback onPressed) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon, color: Colors.white),
//       label: Text(label, style: const TextStyle(color: Colors.white)),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }

//   void _exportAsPDF() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//           content: Text('PDF export functionality would be implemented here')),
//     );
//   }

//   void _exportAsExcel() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//           content:
//               Text('Excel export functionality would be implemented here')),
//     );
//   }

//   void _printReport() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//           content: Text('Print functionality would be implemented here')),
//     );
//   }
// }

// class _SummaryCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final IconData icon;
//   final Color color;

//   const _SummaryCard({
//     required this.title,
//     required this.value,
//     required this.icon,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 8,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(icon, color: color, size: 24),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


