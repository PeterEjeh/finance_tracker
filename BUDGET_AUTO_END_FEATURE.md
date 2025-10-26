# Budget Auto-End Feature Documentation

## Overview
The Budget Auto-End feature automatically manages budget lifecycles with intelligent notifications, performance tracking, and optional auto-renewal capabilities.

## Features

### 1. **Auto-End Timer** ⏰
- Automatically detects when budgets reach their end date
- Deactivates expired budgets
- Sends performance summary notifications

### 2. **Performance Summary** 📊
Displays comprehensive budget performance at the end of each period:
- **Budget Rating System** (0-5 stars):
  - ⭐⭐⭐⭐⭐ (5.0): Under 50% spent - Perfect!
  - ⭐⭐⭐⭐✨ (4.5): Under 70% spent - Excellent!
  - ⭐⭐⭐⭐ (4.0): Under 85% spent - Great!
  - ⭐⭐⭐✨ (3.5): Under 95% spent - Good
  - ⭐⭐⭐ (3.0): 95-100% spent - Acceptable
  - ⭐⭐ (2.0): Up to 10% over - Slightly Over
  - ⭐✨ (1.5): 10-30% over - Over Budget
  - ⭐ (1.0): 30-50% over - Needs Improvement
  - ✨ (0.5): 50%+ over - Significant Overspending

### 3. **Smart Notifications** 🔔
- **3 Days Before End**: Reminder notification
- **1 Day Before End**: Urgent reminder
- **On End Day**: Final reminder
- **After End**: Performance summary with motivational message

### 4. **Auto-Renew Option** 🔄
- Optional automatic budget renewal for next period
- Maintains all settings (amount, alerts, etc.)
- Sends confirmation notification

### 5. **Historical Performance Graph** 📈
- Visual bar chart comparing budget vs actual spending
- Shows last 6 periods by default
- Color-coded: Green (under budget), Red (over budget)
- Star ratings for each period

## Implementation Guide

### Step 1: Update Budget Model
The `Budget` model now includes the `autoRenew` field:

```dart
@HiveField(17)
bool autoRenew; // Whether to automatically renew for next period
```

**Note:** You need to regenerate Hive adapters after this change:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 2: Initialize Service
The service is initialized in `main.dart`:

```dart
await BudgetAutoEndService().initialize();
```

### Step 3: Process Budgets for User
Call this when user logs in or app starts:

```dart
final userId = FirebaseAuth.instance.currentUser?.uid;
if (userId != null) {
  await BudgetAutoEndService().processBudgetsForUser(userId);
}
```

### Step 4: Display Performance Modal
Show the performance summary when a budget ends:

```dart
import '../widgets/budget_performance_modal.dart';

await BudgetPerformanceModal.show(
  context: context,
  budget: budget,
  progress: progress,
  onRenew: () async {
    final renewed = await BudgetAutoEndService().autoRenewBudget(
      budget.id,
      userId,
    );
    if (renewed != null) {
      Navigator.of(context).pop();
      // Show success message
    }
  },
);
```

### Step 5: Display Historical Chart
Add to any screen showing budget details:

```dart
import '../widgets/budget_history_chart.dart';

final history = await BudgetAutoEndService().getBudgetHistory(
  categoryId,
  userId,
  monthsBack: 6,
);

BudgetHistoryChart(
  history: history,
  categoryName: 'Food & Dining',
)
```

## Usage Examples

### Creating a Budget with Auto-Renew
```dart
final budget = await BudgetService.createBudget(
  name: 'Monthly Groceries',
  categoryId: 'food',
  amount: 50000,
  period: BudgetPeriod.monthly,
  userId: userId,
  autoRenew: true, // Enable auto-renewal
  alertThreshold: 0.8,
  alertEnabled: true,
);

// Schedule notifications
await BudgetAutoEndService().processBudgetsForUser(userId);
```

### Manually Ending a Budget
```dart
await BudgetAutoEndService().manuallyEndBudget(
  budgetId,
  userId,
);
```

### Getting Budget Rating
```dart
final progress = await BudgetService.getBudgetProgress(budgetId, userId);
final rating = BudgetAutoEndService().calculateBudgetRating(progress);
final stars = BudgetAutoEndService().getBudgetRatingStars(rating);
print('Your rating: $stars ($rating/5.0)');
```

### Checking Budget History
```dart
final history = await BudgetAutoEndService().getBudgetHistory(
  categoryId,
  userId,
  monthsBack: 12, // Last 12 periods
);

for (final item in history) {
  final budget = item['budget'] as Budget;
  final rating = item['rating'] as double;
  final stars = BudgetAutoEndService().getBudgetRatingStars(rating);
  print('${budget.name}: $stars');
}
```

## Notification Types

### 1. Budget Expiry Notification
**Time:** 9:00 PM on end date  
**Title:** "[Budget Name] Budget Ended"  
**Body:** "Your [period] budget has ended. Tap to view performance summary."

### 2. Performance Summary Notification
**Time:** Immediately after budget ends  
**Title:** "[Budget Name] Performance Summary"  
**Body:** Varies based on performance:
- 🎉 "Great job! Saved ₦X (Y% under budget)"
- ✅ "Well done! Spent ₦X of ₦Y (Z%)"
- ❌ "Over budget by ₦X! Spent ₦Y of ₦Z"

### 3. Reminder Notifications
**Times:** 10:00 AM on reminder days  
**Title:** "Budget Reminder"  
**Body:**
- 3 days: "Your [Budget Name] budget ends in 3 days"
- 1 day: "Your [Budget Name] budget ends tomorrow"
- 0 days: "Your [Budget Name] budget ends today"

### 4. Auto-Renewal Notification
**Time:** Immediately after renewal  
**Title:** "Budget Renewed"  
**Body:** "[Budget Name] has been renewed for the next [period]"

## Performance Metrics

### Budget Rating Calculation
The rating is calculated based on spending percentage:

```dart
double calculateBudgetRating(Map<String, dynamic> progress) {
  final spentPercentage = progress['spentPercentage'] as double;
  final isOverBudget = progress['isOverBudget'] as bool;
  
  if (isOverBudget) {
    final overPercentage = spentPercentage - 1.0;
    if (overPercentage > 0.5) return 0.5; // 50%+ over
    if (overPercentage > 0.3) return 1.0; // 30-50% over
    if (overPercentage > 0.1) return 1.5; // 10-30% over
    return 2.0; // Less than 10% over
  }
  
  if (spentPercentage < 0.5) return 5.0;  // Under 50%
  if (spentPercentage < 0.7) return 4.5;  // Under 70%
  if (spentPercentage < 0.85) return 4.0; // Under 85%
  if (spentPercentage < 0.95) return 3.5; // Under 95%
  return 3.0; // 95-100%
}
```

## UI Components

### Budget Performance Modal
A beautiful modal dialog showing:
- Budget name and period
- Star rating with color-coded badge
- Spending details (Budget, Spent, Remaining)
- Progress bar
- Performance message with emoji
- Action buttons (Renew/Done)

### Budget History Chart
Interactive bar chart displaying:
- Budget amount (light blue background bar)
- Actual spending (green/red foreground bar)
- Period labels (MMM YY format)
- Touch tooltips with detailed info
- Legend explaining colors

## Best Practices

### 1. Call Budget Processing on Login
```dart
// In your AuthWrapper or Dashboard initialization
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  await BudgetAutoEndService().processBudgetsForUser(user.uid);
}
```

### 2. Periodic Background Checks
The service automatically checks every 4 hours, but you can also:
```dart
// Check on app resume
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      BudgetAutoEndService().processBudgetsForUser(userId);
    }
  }
}
```

### 3. Show Performance Modal Proactively
```dart
// Check for recently ended budgets on dashboard
final allBudgets = await BudgetService.getAllBudgets(userId);
final recentlyEnded = allBudgets.where((b) => 
  !b.isActive && 
  DateTime.now().difference(b.endDate).inDays <= 1
).toList();

if (recentlyEnded.isNotEmpty && context.mounted) {
  final budget = recentlyEnded.first;
  final progress = await BudgetService.getBudgetProgress(budget.id, userId);
  
  await BudgetPerformanceModal.show(
    context: context,
    budget: budget,
    progress: progress,
  );
}
```

## Customization

### Modify Notification Times
In `budget_auto_end_service.dart`:

```dart
// Change end notification time
final endDateTime = DateTime(
  budget.endDate.year,
  budget.endDate.month,
  budget.endDate.day,
  21, // Change to your preferred hour
  0,
);

// Change reminder notification time
final reminderDateTime = DateTime(
  reminderDate.year,
  reminderDate.month,
  reminderDate.day,
  10, // Change to your preferred hour
  0,
);
```

### Customize Rating Thresholds
Adjust the rating calculation logic to match your preferences:

```dart
// More lenient rating
if (spentPercentage < 0.6) return 5.0;  // Under 60% = Perfect
if (spentPercentage < 0.8) return 4.5;  // Under 80% = Excellent
```

### Change Notification Messages
Edit `_generatePerformanceSummary()` in the service:

```dart
if (isOverBudget) {
  return 'Your custom over-budget message';
} else if (spentPercentage < 0.7) {
  return 'Your custom excellent performance message';
}
```

## Troubleshooting

### Notifications Not Showing
1. Check notification permissions in app settings
2. Verify `NotificationService` is initialized
3. Check `SettingsService().getNotifications()` returns true
4. Ensure timezone is properly initialized

### Budgets Not Auto-Ending
1. Verify `BudgetAutoEndService().initialize()` was called
2. Check that `processBudgetsForUser()` is called with correct userId
3. Ensure budget's `endDate` has passed

### Auto-Renew Not Working
1. Check `budget.autoRenew` is set to `true`
2. Regenerate Hive adapters if you just added the field
3. Verify `_processExpiredBudgets()` is being called

## Future Enhancements

Potential improvements for the feature:

1. **Customizable Notification Schedule**: Allow users to set their own reminder days
2. **Push Notifications**: Integration with FCM for cross-device notifications
3. **Performance Insights**: AI-powered spending pattern analysis
4. **Budget Recommendations**: Suggest optimal budget amounts based on history
5. **Comparative Analysis**: Compare performance across categories
6. **Export Reports**: Generate PDF reports of budget performance
7. **Gamification**: Achievements and badges for consistent budget adherence
8. **Social Features**: Share accomplishments with friends (optional)

## Dependencies

Required packages (already in your project):
- `flutter_local_notifications` - Local notifications
- `timezone` - Timezone handling
- `intl` - Date/number formatting
- `hive` - Local storage
- `fl_chart` - Chart visualization (needed for history chart)

If `fl_chart` is not in your project, add it to `pubspec.yaml`:
```yaml
dependencies:
  fl_chart: ^0.65.0
```

## Support

For issues or questions:
1. Check this documentation
2. Review the source code comments
3. Test with different budget scenarios
4. Enable debug logging in the service

## License

This feature is part of the Finance Tracker app and follows the same license.
