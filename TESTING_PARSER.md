# Testing Natural Language Parser

## Setup
Make sure all new files are added to the Xcode project:
1. Open Nota.xcodeproj in Xcode
2. Check that these files appear in the project navigator:
   - `Nota/Models/ParsedInput.swift`
   - `Nota/Services/NaturalLanguageParser.swift`
   - `Nota/Views/Components/ParsedTaskNotification.swift`
3. If any are missing, right-click the appropriate folder and "Add Files to Nota..."

## What to Test

### 1. Basic Parsing
Type these examples and press Return:
- `Dinner next Friday at 7`
- `Buy groceries tomorrow`
- `Team meeting this Thursday at 2pm in Conference Room`
- `Finish presentation slides`

### 2. Expected Behavior
When you press Return:
1. **Console Output** - You should see debug logs like:
   ```
   🔑 Return key pressed, text: Dinner next Friday at 7
   📝 Submitting line: Dinner next Friday at 7
   🔍 Parsed result: intent=event, date=Optional(2025-10-...), time=Optional("7:00 PM"), ...
   ```

2. **Notification Popup** - A colored notification should slide up from the bottom with:
   - Event type badge (calendar icon for events, checkmark for tasks)
   - Target date
   - **Jump button** to navigate to that date
   - Info button (i) to expand details (time, location, confidence)

3. **Auto-routing** - If you typed "next Friday", the task should be added to Friday's date (not today)

### 3. Notification Colors
- **Purple** = Event (dinner, meeting, appointment)
- **Blue** = Task (buy, finish, send)
- **Orange** = Note
- **Gray** = Unknown

### 4. Jump Button
Click "Jump" on the notification:
- Should animate to the target date
- Week view should scroll to the correct week
- Selected date should change to match

## Debugging

### If Return key does nothing:
1. Check Xcode console for the "🔑 Return key pressed" message
2. If you don't see it, the TextField might not have focus
3. Try tapping the text field first

### If no notification appears:
1. Check console for "📝 Submitting line" message
2. If you see errors about ParsedInput or NaturalLanguageParser, the files might not be in the build target
3. In Xcode, select each new file → File Inspector → ensure "Nota" is checked under "Target Membership"

### If parsing seems wrong:
1. Check the console output for parsed values
2. The confidence score should be > 0.5 for good parses
3. Try variations of the input

## Example Console Output

```
🔑 Return key pressed, text: Dinner next Friday at 7
📝 Submitting line: Dinner next Friday at 7
🔍 Parsed result: intent=event, date=Optional(2025-10-31), time=Optional("7:00"), location=nil, confidence=0.9
```
