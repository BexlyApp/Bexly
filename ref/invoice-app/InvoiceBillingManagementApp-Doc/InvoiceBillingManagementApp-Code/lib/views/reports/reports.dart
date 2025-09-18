import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

// Import your report screens here
import 'package:invoiceandbilling/views/reports/payment.dart';
import 'package:invoiceandbilling/views/reports/purchase.dart';
import 'package:invoiceandbilling/views/reports/purchasereturn.dart';
import 'package:invoiceandbilling/views/reports/qotationreport.dart';
import 'package:invoiceandbilling/views/reports/salesreport.dart';
import 'package:invoiceandbilling/views/reports/stockreport.dart';
import '../../Widgets/customapp_bar.dart';
import 'expensesreports.dart';

class ReportsScreen extends StatelessWidget {
  final List<ReportItem> reports = [
    ReportItem(
      title: 'Expense Report',
      icon: Iconsax.chart_2,
      color: const Color(0xFFFF6B6B),
      secondaryColor: const Color(0xFFFF8E8E),
      page: IncomeReportScreen(),
    ),
    ReportItem(
      title: 'Purchase Report',
      icon: Iconsax.shopping_cart,
      color: const Color(0xFF4ECDC4),
      secondaryColor: const Color(0xFF7CDFD8),
      page: PurchaseReportScreen(),
    ),
    ReportItem(
      title: 'Purchase Return',
      icon: Iconsax.arrow_swap_horizontal,
      color: const Color(0xFFFFA07A),
      secondaryColor: const Color(0xFFFFB896),
      page: PurchaseReturnReportScreen(),
    ),
    ReportItem(
      title: 'Sales Report',
      icon: Iconsax.shop,
      color: const Color(0xFF9575CD),
      secondaryColor: const Color(0xFFB39DDB),
      page: SalesReturnScreen(),
    ),
    ReportItem(
      title: 'Quotation Report',
      icon: Iconsax.document_text,
      color: const Color(0xFF64B5F6),
      secondaryColor: const Color(0xFF90CAF9),
      page: QuotationReportScreen(),
    ),
    ReportItem(
      title: 'Payment Report',
      icon: Iconsax.card,
      color: const Color(0xFF81C784),
      secondaryColor: const Color(0xFFA5D6A7),
      page: PaymentReportScreen(),
    ),
    ReportItem(
      title: 'Stock Report',
      icon: Iconsax.box,
      color: const Color(0xFFFFD54F),
      secondaryColor: const Color(0xFFFFE082),
      page: StockReportScreen(),
    ),
    ReportItem(
      title: 'Income Report',
      icon: Iconsax.chart_1,
      color: const Color(0xFFF06292),
      secondaryColor: const Color(0xFFF48FB1),
      page: IncomeReportScreen(),
    ),
  ];

   ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const CustomAppBar(text: 'Reports Dashboard', text1: ''),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: reports.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return ReportCard(
                      report: report,
                      index: index,
                    ).animate().scaleXY(
                      begin: 0.8,
                      end: 1,
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                      delay: (100 * index).ms,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportCard extends StatefulWidget {
  final ReportItem report;
  final int index;

  const ReportCard({super.key,
    required this.report,
    required this.index,
  });

  @override
  State<ReportCard> createState() => ReportCardState();
}

class ReportCardState extends State<ReportCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: 600.ms,
        transform: Matrix4.identity()..scale(_isHovering ? 1.03 : 1.0),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: 700.ms,
              pageBuilder: (_, __, ___) => widget.report.page,
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation.drive(
                      Tween<double>(begin: 0.9, end: 1.0)
                          .chain(CurveTween(curve: Curves.easeOut)),
                    ),
                    child: child,
                  ),
                );
              },
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.report.color,
                  widget.report.secondaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.report.color.withAlpha((0.2 * 255).toInt()),
                  blurRadius: _isHovering ? 20 : 10,
                  spreadRadius: _isHovering ? 2 : 1,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      widget.report.icon,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.report.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_isHovering)
                    const Icon(
                      Iconsax.arrow_right_3,
                      size: 20,
                      color: Colors.white,
                    ).animate().slideX(
                      begin: -0.5,
                      end: 0,
                      curve: Curves.easeOut,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReportItem {
  final String title;
  final IconData icon;
  final Color color;
  final Color secondaryColor;
  final Widget page;

  ReportItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.secondaryColor,
    required this.page,
  });
}