import SwiftUI

struct BookingView: View {
    @State private var selectedDate = Date()
    @State private var selectedType: AppointmentType?
    @State private var availableSlots: [Date] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Calendar
                    calendarSection

                    // Appointment type picker
                    appointmentTypeSection

                    // Available times
                    if selectedType != nil {
                        availableTimesSection
                    }

                    // Upcoming appointments
                    upcomingSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Book")
        }
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Date")
                .font(.mdHeadline)

            DatePicker(
                "Date",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(.mdOrange)
        }
        .mdCard()
    }

    private var appointmentTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appointment Type")
                .font(.mdHeadline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AppointmentType.allCases, id: \.self) { type in
                    AppointmentTypeCard(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        withAnimation {
                            selectedType = type
                            loadAvailableSlots()
                        }
                    }
                }
            }
        }
        .mdCard()
    }

    private var availableTimesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Available Times")
                    .font(.mdHeadline)
                Spacer()
                Text(selectedDate, style: .date)
                    .font(.mdCaption)
                    .foregroundColor(.mdGray)
            }

            if availableSlots.isEmpty {
                Text("No available slots for this date")
                    .font(.mdSubheadline)
                    .foregroundColor(.mdGray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(availableSlots, id: \.self) { slot in
                        TimeSlotButton(time: slot) {
                            // TODO: Proceed to confirmation
                        }
                    }
                }
            }
        }
        .mdCard()
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Appointments")
                .font(.mdHeadline)

            ForEach(Appointment.samples) { appointment in
                AppointmentRow(appointment: appointment)
            }
        }
        .mdCard()
    }

    private func loadAvailableSlots() {
        // Mock available slots
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: selectedDate)
        availableSlots = [9, 10, 11, 14, 15, 16].compactMap { hour in
            calendar.date(bySettingHour: hour, minute: 0, second: 0, of: baseDate)
        }
    }
}

struct AppointmentTypeCard: View {
    let type: AppointmentType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .mdOrange)

                Text(type.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)

                Text("\(type.defaultDuration) min")
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .mdGray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.mdOrange : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.mdOrange.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct TimeSlotButton: View {
    let time: Date
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(time, style: .time)
                .font(.mdSubheadline)
                .foregroundColor(.mdOrange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.mdOrange.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

struct AppointmentRow: View {
    let appointment: Appointment

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Text(appointment.date, format: .dateTime.month(.abbreviated))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.mdOrange)
                Text(appointment.date, format: .dateTime.day())
                    .font(.system(size: 20, weight: .bold))
            }
            .frame(width: 48, height: 48)
            .background(Color.mdOrange.opacity(0.1))
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.type.displayName)
                    .font(.mdBody)
                Text(appointment.formattedTime)
                    .font(.mdCaption)
                    .foregroundColor(.mdGray)
            }

            Spacer()

            Text(appointment.status.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.mdOrange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.mdOrange.opacity(0.1))
                .cornerRadius(4)
        }
    }
}

#Preview {
    BookingView()
}
