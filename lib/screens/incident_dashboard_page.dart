import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentDashboardPage extends StatelessWidget {
  final String incidentId;

  const IncidentDashboardPage({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF8C42), // Orange
              Color(0xFF1E3A8A), // Blue
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('incidents')
                .doc(incidentId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF8C42),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Incident not found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data!.data()!;
              final progress = data['progress'] as Map<String, dynamic>? ?? {};
              final imageUrl = data['imageUrl'] ?? '';

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Incident Details',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 🔹 Incident Image from Supabase
                    if (imageUrl.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            imageUrl,
                            height: 220,
                            width: 220,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    if (imageUrl.isNotEmpty) const SizedBox(height: 24),

                    _buildInfoCard(
                      context,
                      'Incident Name',
                      data['name'] ?? 'Unknown',
                      Icons.info_rounded,
                      Colors.orange.shade400,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      'Location',
                      data['address'] ?? 'Unknown',
                      Icons.location_on_rounded,
                      Colors.orange.shade400,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      'Urgency Level',
                      data['urgency'] ?? 'Unknown',
                      Icons.priority_high_rounded,
                      _getUrgencyColor(data['urgency'] ?? 'Unknown'),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      'Current Status',
                      data['status'] ?? 'Reported',
                      Icons.check_circle_rounded,
                      _getStatusColor(data['status'] ?? 'Reported'),
                    ),
                    const SizedBox(height: 40),

                    Text(
                      'Resolution Progress',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildProgressIndicator(context, progress),
                    const SizedBox(height: 24),

                    _buildStatusBox(
                      context,
                      'Accepted by Admin',
                      progress['accepted'] ?? false,
                      Icons.person,
                    ),
                    const SizedBox(height: 12),
                    _buildStatusBox(
                      context,
                      'Reported to LGU',
                      progress['reportedToLGU'] ?? false,
                      Icons.send_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildStatusBox(
                      context,
                      'Under Surveillance',
                      progress['onAction'] ?? false,
                      Icons.visibility_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildStatusBox(
                      context,
                      'Problem Resolved',
                      progress['solved'] ?? false,
                      Icons.done_all_rounded,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    Map<String, dynamic> progress,
  ) {
    final completedSteps = [
      progress['accepted'],
      progress['reportedToLGU'],
      progress['onAction'],
      progress['solved'],
    ].where((s) => s == true).length;
    final totalSteps = 4;
    final progressPercentage = completedSteps / totalSteps;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Completion',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progressPercentage * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Color(0xFFFF8C42),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPercentage,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF8C42),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Step $completedSteps of $totalSteps completed',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox(
    BuildContext context,
    String label,
    bool checked,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: checked
            ? const Color(0xFFFF8C42).withOpacity(0.1)
            : Colors.white.withOpacity(0.03),
        border: Border.all(
          color: checked
              ? const Color(0xFFFF8C42).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: checked
            ? [
                BoxShadow(
                  color: const Color(0xFFFF8C42).withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: checked
                  ? const Color(0xFFFF8C42).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              checked ? Icons.check_circle_rounded : icon,
              color: checked
                  ? const Color(0xFFFF8C42)
                  : Colors.white.withOpacity(0.4),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: checked
                    ? const Color(0xFFFF8C42)
                    : Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          if (checked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C42).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Complete',
                style: TextStyle(
                  color: Color(0xFFFF8C42),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return Colors.red.shade400;
      case 'high':
        return Colors.orange.shade400;
      case 'medium':
        return Colors.yellow.shade600;
      default:
        return Colors.blue.shade400;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.blue.shade400;
      case 'in progress':
        return Colors.orange.shade400;
      case 'pending':
        return Colors.grey.shade400;
      default:
        return Colors.blue.shade400;
    }
  }
}
