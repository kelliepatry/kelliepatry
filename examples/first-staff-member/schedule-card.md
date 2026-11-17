# SCHEDULE CARD · punch-list coordinator

Design card, not installed automation. The tutorial creates notification issues; the
owner manually starts AI shifts. Quiet alarms and end-to-end health checks remain unwired.

Sensor (wakes on a change):
  - a new punch-list packet that says something different from the last one
  - a new email at the coordinator's address

Clock (wakes because time is the reason):
  - Friday 3 pm: one weekly summary of what was raised, what was answered, what is still open

Heartbeat (worker only; end-to-end delivery still needs a check):
  - inspect the punch-list worker's weekday-morning run
  - separately verify issue arrival and shift pickup; the tutorial does not automate this

Quiet alarm (silence that means something is wrong):
  - no packet for 3 working days, or no email at the address for 10 working days
  - goes to the owner by a different route than the one that might have failed

Working hours (when it may act, not when it may wake):
  - drafts any time
  - anything that will leave the business is held for the owner, Monday to Friday, 8 am to 5 pm

The owner's rhythm:
  - Monday: a short brief that says what matters this week
  - end of each day: open questions answered in one sitting
  - release: nothing goes out until the owner says so
