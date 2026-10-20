# Fabla: Tester's Guide

A short guide to reporting bugs from inside the app using Fabla. This is for testers and beta users, not developers. If Fabla has been added to a build you're testing, everything below is all you need.

## What Fabla does

When you run into something broken, Fabla lets you report it without leaving the app or writing a separate email. One tap grabs a screenshot of what's on screen, a trail of what you just did, and your device details, then bundles it into a report a developer can act on. You just add a sentence or two describing the problem.

## Finding the report button

Look for a small round red button with a bug icon floating over the app. It sits toward the right edge of the screen by default and stays on top of whatever you're doing.

If it's ever covering something you need to see or tap, drag it. Press and hold, then slide it anywhere on the screen and let go.

If you don't see the button at all, the build you're testing may not have it switched on. Let the person who gave you the build know, and they can enable it.

## Reporting a bug, step by step

1. Get the app to the exact screen where the problem is showing. Fabla captures whatever is on screen the moment you tap, so it helps to report from the screen where the bug is visible.
2. Tap the red bug button.
3. Fabla takes a snapshot and opens the "Report a Bug" screen. This takes a second.
4. Fill in what went wrong (see below) and tap Submit.

That's the whole flow. You don't need to attach anything or copy any logs yourself.

## The "Report a Bug" screen

After you tap the button, a form opens with everything already gathered for you:

Screenshot preview. At the top you'll see the image Fabla captured, so you can confirm it caught the right moment.

Screen. Just below, the name of the screen you were on when you tapped.

What happened? This is the one part you fill in, and it's required. Describe the bug and, if you can, how to make it happen again. This box is the most valuable thing in the whole report, so it's worth a clear sentence or two.

Breadcrumbs. A collapsible list showing the trail of what you did just before reporting: screens you moved through, buttons you tapped, network activity, and so on. This is gathered automatically. You can tap to expand it and take a look, but you don't need to change anything.

Device info. Your device model, operating system version, and app version, gathered automatically.

Submit. The button at the bottom that sends everything.

To back out without sending, tap the X (close) in the top corner.

## Writing a report that helps

The description box is where a good report is made. A few things that make a developer's life much easier:

- Say what actually happened, in plain words. "The save button does nothing when I tap it" beats "it's broken."
- Say what you expected to happen instead.
- List the steps to reproduce it if you know them, for example "Open a diary, tap edit, then tap save."
- Note anything unusual about the moment, like it only happens the second time, or only on a slow connection.

You don't need to describe your phone or list what you tapped. Fabla already captured that.

## Submitting

Tap Submit when you're done.

If you leave the description empty, you'll see "Please describe what went wrong" and the report won't send until you add something.

Once it goes through, the form closes and a short "Bug report submitted" message appears at the bottom of the screen. That message has a View button. Tapping it opens the report that was created (for example, the GitHub issue), so you can follow along or add more later.

If you see "Captured locally" instead, the report was saved on the device but not sent anywhere. That usually means the build isn't connected to a reporting backend yet. Mention it to whoever gave you the build.

## What gets sent

So you know exactly what leaves your device when you submit:

- The screenshot taken the moment you tapped the button.
- Your written description.
- The breadcrumb trail (screens, taps, network calls, and app open/close events from roughly your last 50 actions).
- Basic device details: model, OS version, and app version.

Because a screenshot and your recent activity are included, avoid reporting from a screen showing anything private, such as passwords or personal details you'd rather not share, or clear the screen first.

## Quick answers

The button is in my way. Drag it somewhere else. Press, hold, and slide.

I opened the report screen by accident. Tap the X in the top corner to close it. Nothing is sent until you tap Submit.

Nothing happened after I hit Submit. Check your connection and try again. If it keeps failing, an error message will appear on the form explaining what went wrong.

I found several bugs. File them one at a time, each from the screen where it happens. Separate reports are easier to track than one long one.
