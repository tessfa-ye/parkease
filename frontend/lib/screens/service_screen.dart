import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../widgets/active_parking_session_card.dart';
import '../services/booking_store.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingStore = BookingStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.services),
      ),
      body: ListenableBuilder(
        listenable: bookingStore,
        builder: (context, _) {
          final bookings = bookingStore.activeBookings;
          if (bookings.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => bookingStore.init(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.local_parking, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No active parking sessions.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => bookingStore.init(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return ActiveParkingSessionCard(
                  key: ValueKey('${booking.id}_${booking.startTime.millisecondsSinceEpoch}_${booking.endTime.millisecondsSinceEpoch}'),
                  booking: booking,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
