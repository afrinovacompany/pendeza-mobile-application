Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

Try the new cross-platform PowerShell https://aka.ms/pscore6

PS D:\A.Projects\pendeza> claude
<<
▐▛███▜▌   Claude Code v2.1.34
▝▜█████▛▘  Opus 4.6 · Claude Pro
▘▘ ▝▝    D:\A.Projects\pendeza

↑ Install the PyCharm plugin from the JetBrains Marketplace: https://docs.claude.com/s/claude-code-jetbrains

❯ You  enhanced   dashboard,   calender  But Also  ensure  No  Localization  error  I  see  some  jey  missing  like  owner.dashboard.loading              
owner.dashboard.error_title                                                                                                                          
owner.dashboard.todays_overview  So  inshort  ensure  that  the  Owner  side  user  role  UI/UX  is  very  pro  and  Industry  level                                                                                                                                                                                
● Let me start by exploring the current state of the owner side - dashboard, calendar, and localization files.

● Explore(Explore owner side codebase)                                                                                                                       ⎿  Done (24 tool uses · 94.1k tokens · 2m 10s)

● Now let me read the key files I need to modify directly.

● Read 4 files (ctrl+o to expand)                                                                                                                                                                                                                                                                                     
● Now let me read the remaining widget files and the dashboard header.                                                                                                                                                                                                                                                
● Read 4 files (ctrl+o to expand)                                                                                                                                                                                                                                                                                     
● Now I have a complete picture. Let me create tasks and start working on all the fixes.

● Starting with the localization keys. I need to add all missing keys for the owner dashboard, calendar, and all hardcoded strings across the widgets.                                                                
6 tasks (0 done, 1 in progress, 5 open) · ctrl+t to hide tasks                                                                                           
◼ Fix missing localization keys in en.json and sw.json                                                                                                   
◻ Localize hardcoded strings in dashboard_header.dart                                                                                                    
◻ Localize hardcoded strings in upcoming_appointments_list.dart                                                                                          
◻ Localize hardcoded strings in appointment_details_dialog.dart                                                                                          
◻ Enhance owner dashboard with occupancy rate KPI and polish                                                                                             
◻ Enhance calendar screen with status legend and quick actions                                                                                                                                                                                                                                                      ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── Edit file                                                                                                                                               
assets\language\en.json                                                                                                                                   ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
310        "help_subtitle": "FAQs and support"
311      },
312      "dashboard": {
313 +      "loading": "Loading your dashboard...",                                                                                                        
314 +      "error_title": "Something Went Wrong",                                                                                                         
315 +      "error_retry": "Retry",                                                                                                                        
316 +      "todays_overview": "Today's Overview",                                                                                                         
317        "revenue": "Today's Revenue",
318        "appointments": "Appointments",
319        "appointments_today": "{} Today",
320        "new_clients": "New Clients",
321        "clients_week": "{} This Week",
322 +      "occupancy": "Occupancy",                                                                                                                      
323 +      "occupancy_rate": "{}%",                                                                                                                       
324        "promotions": "Promotions",
325        "promotions_desc": "Boost Sales",
326        "upcoming": "Upcoming Appointments",
327 +      "upcoming_count": "{} upcoming",                                                                                                               
328 +      "no_upcoming": "No upcoming appointments",                                                                                                     
329 +      "no_upcoming_desc": "No bookings scheduled for the next 7 days",                                                                               
330        "manage_salon": "Manage Salon Profile",
331 -      "manage_salon_desc": "Edit photos, hours, contact info & more"                                                                                 
331 +      "manage_salon_desc": "Edit photos, hours, contact info & more",
332 +      "greeting_morning": "Good Morning",                                                                                                            
333 +      "greeting_afternoon": "Good Afternoon",                                                                                                        
334 +      "greeting_evening": "Good Evening",                                                                                                            
335 +      "notifications_coming_soon": "Notifications coming soon!",                                                                                     
336 +      "services_count": "{} service(s)",                                                                                                             
337 +      "view_schedule": "View Full Schedule"                                                                                                          
338      },
339      "calendar": {
340        "title": "My Schedule",
341 +      "week_view": "Week View",                                                                                                                      
342 +      "month_view": "Month View",                                                                                                                    
343        "list_header": "Appointments for {}",
344        "no_appointments": "No Appointments",
345        "no_appointments_msg": "No appointments scheduled for this day.",
346 -      "services_count": "service(s)"                                                                                                                 
346 +      "services_count": "service(s)",
347 +      "appointment_details": "Appointment Details",                                                                                                  
348 +      "client_section": "Client",                                                                                                                    
349 +      "date_time_section": "Date & Time",                                                                                                            
350 +      "services_section": "Services Booked",                                                                                                         
351 +      "status_section": "Status",                                                                                                                    
352 +      "no_services_found": "No services found",                                                                                                      
353 +      "total_label": "Total: {}",                                                                                                                    
354 +      "minutes_label": "{} minutes",                                                                                                                 
355 +      "mark_complete": "Mark Complete",                                                                                                              
356 +      "mark_complete_title": "Mark as Complete",                                                                                                     
357 +      "mark_complete_confirm": "Are you sure you want to mark this appointment as completed?",                                                       
358 +      "mark_complete_success": "Appointment marked as completed",                                                                                    
359 +      "cancel_title": "Cancel Appointment",                                                                                                          
360 +      "cancel_confirm": "Are you sure you want to cancel this appointment? This action cannot be undone.",                                           
361 +      "cancel_keep": "No, Keep It",                                                                                                                  
362 +      "cancel_yes": "Yes, Cancel",                                                                                                                   
363 +      "cancel_success": "Appointment cancelled",                                                                                                     
364 +      "unknown_client": "Unknown Client",                                                                                                            
365 +      "status_confirmed": "Confirmed",                                                                                                               
366 +      "status_completed": "Completed",                                                                                                               
367 +      "status_cancelled": "Cancelled",                                                                                                               
368 +      "status_pending_payment": "Pending Payment",                                                                                                   
369 +      "status_no_show": "No Show",                                                                                                                   
370 +      "status_payment_failed": "Payment Failed"                                                                                                      
371      },
372      "services": {
373        "title": "Manage Services",
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
Do you want to make this edit to en.json?
❯ 1. Yes
2. Yes, allow all edits during this session (meta+m)
3. No

Esc to cancel · Tab to amend

▐▛███▜▌   Claude Code v2.1.34
▝▜█████▛▘  Opus 4.6 · Claude Pro
▘▘ ▝▝    D:\A.Projects\pendeza

↑ Install the PyCharm plugin from the JetBrains Marketplace: https://docs.claude.com/s/claude-code-jetbrains

❯ You  enhanced   dashboard,   calender  But Also  ensure  No  Localization  error  I  see  some  jey  missing  like  owner.dashboard.loading              
owner.dashboard.error_title                                                                                                                              
owner.dashboard.todays_overview  So  inshort  ensure  that  the  Owner  side  user  role  UI/UX  is  very  pro  and  Industry  level

● Let me start by exploring the current state of the owner side - dashboard, calendar, and localization files.

● Explore(Explore owner side codebase)
⎿  Done (24 tool uses · 94.1k tokens · 2m 10s)

● Now let me read the key files I need to modify directly.

● Read 4 files (ctrl+o to expand)

● Now let me read the remaining widget files and the dashboard header.

● Read 4 files (ctrl+o to expand)

● Now I have a complete picture. Let me create tasks and start working on all the fixes.

● Starting with the localization keys. I need to add all missing keys for the owner dashboard, calendar, and all hardcoded strings across the widgets.

● Update(assets\language\en.json)

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Edit file
assets\language\en.json
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
310        "help_subtitle": "FAQs and support"
311      },
312      "dashboard": {
313 +      "loading": "Loading your dashboard...",                                                                                                        
314 +      "error_title": "Something Went Wrong",                                                                                                         
315 +      "error_retry": "Retry",                                                                                                                        
316 +      "todays_overview": "Today's Overview",                                                                                                         
317        "revenue": "Today's Revenue",
318        "appointments": "Appointments",
319        "appointments_today": "{} Today",
320        "new_clients": "New Clients",
321        "clients_week": "{} This Week",
322 +      "occupancy": "Occupancy",                                                                                                                      
323 +      "occupancy_rate": "{}%",                                                                                                                       
324        "promotions": "Promotions",
325        "promotions_desc": "Boost Sales",
326        "upcoming": "Upcoming Appointments",
327 +      "upcoming_count": "{} upcoming",                                                                                                               
328 +      "no_upcoming": "No upcoming appointments",                                                                                                     
329 +      "no_upcoming_desc": "No bookings scheduled for the next 7 days",                                                                               
330        "manage_salon": "Manage Salon Profile",
331 -      "manage_salon_desc": "Edit photos, hours, contact info & more"                                                                                 
331 +      "manage_salon_desc": "Edit photos, hours, contact info & more",
332 +      "greeting_morning": "Good Morning",                                                                                                            
333 +      "greeting_afternoon": "Good Afternoon",                                                                                                        
334 +      "greeting_evening": "Good Evening",                                                                                                            
335 +      "notifications_coming_soon": "Notifications coming soon!",                                                                                     
336 +      "services_count": "{} service(s)",                                                                                                             
337 +      "view_schedule": "View Full Schedule"                                                                                                          
338      },
339      "calendar": {
340        "title": "My Schedule",
341 +      "week_view": "Week View",                                                                                                                      
342 +      "month_view": "Month View",                                                                                                                    
343        "list_header": "Appointments for {}",
344        "no_appointments": "No Appointments",
345        "no_appointments_msg": "No appointments scheduled for this day.",
346 -      "services_count": "service(s)"                                                                                                                 
346 +      "services_count": "service(s)",
347 +      "appointment_details": "Appointment Details",                                                                                                  
348 +      "client_section": "Client",                                                                                                                    
349 +      "date_time_section": "Date & Time",                                                                                                            
350 +      "services_section": "Services Booked",                                                                                                         
351 +      "status_section": "Status",                                                                                                                    
352 +      "no_services_found": "No services found",                                                                                                      
353 +      "total_label": "Total: {}",                                                                                                                    
354 +      "minutes_label": "{} minutes",                                                                                                                 
355 +      "mark_complete": "Mark Complete",                                                                                                              
356 +      "mark_complete_title": "Mark as Complete",                                                                                                     
357 +      "mark_complete_confirm": "Are you sure you want to mark this appointment as completed?",                                                       
358 +      "mark_complete_success": "Appointment marked as completed",                                                                                    
359 +      "cancel_title": "Cancel Appointment",                                                                                                          
360 +      "cancel_confirm": "Are you sure you want to cancel this appointment? This action cannot be undone.",                                           
361 +      "cancel_keep": "No, Keep It",                                                                                                                  
362 +      "cancel_yes": "Yes, Cancel",                                                                                                                   
363 +      "cancel_success": "Appointment cancelled",                                                                                                     
364 +      "unknown_client": "Unknown Client",                                                                                                            
365 +      "status_confirmed": "Confirmed",                                                                                                               
366 +      "status_completed": "Completed",                                                                                                               
367 +      "status_cancelled": "Cancelled",                                                                                                               
368 +      "status_pending_payment": "Pending Payment",                                                                                                   
369 +      "status_no_show": "No Show",                                                                                                                   
370 +      "status_payment_failed": "Payment Failed"                                                                                                      
371      },
372      "services": {
373        "title": "Manage Services",
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
Do you want to make this edit to en.json?
❯ 1. Yes
2. Yes, allow all edits during this session (meta+m)
3. No

Esc to cancel · Tab to amend

▐▛███▜▌   Claude Code v2.1.34
▝▜█████▛▘  Opus 4.6 · Claude Pro
▘▘ ▝▝    D:\A.Projects\pendeza

↑ Install the PyCharm plugin from the JetBrains Marketplace: https://docs.claude.com/s/claude-code-jetbrains

❯ You  enhanced   dashboard,   calender  But Also  ensure  No  Localization  error  I  see  some  jey  missing  like  owner.dashboard.loading              
owner.dashboard.error_title                                                                                                                              
owner.dashboard.todays_overview  So  inshort  ensure  that  the  Owner  side  user  role  UI/UX  is  very  pro  and  Industry  level

● Let me start by exploring the current state of the owner side - dashboard, calendar, and localization files.

● Explore(Explore owner side codebase)
⎿  Done (24 tool uses · 94.1k tokens · 2m 10s)

● Now let me read the key files I need to modify directly.

● Read 4 files (ctrl+o to expand)

● Now let me read the remaining widget files and the dashboard header.

● Read 4 files (ctrl+o to expand)

● Now I have a complete picture. Let me create tasks and start working on all the fixes.

● Starting with the localization keys. I need to add all missing keys for the owner dashboard, calendar, and all hardcoded strings across the widgets.

● Update(assets\language\en.json)

6 tasks (0 done, 1 in progress, 5 open) · ctrl+t to hide tasks
◼ Fix missing localization keys in en.json and sw.json
◻ Localize hardcoded strings in dashboard_header.dart
◻ Localize hardcoded strings in upcoming_appointments_list.dart
◻ Localize hardcoded strings in appointment_details_dialog.dart
◻ Enhance owner dashboard with occupancy rate KPI and polish
◻ Enhance calendar screen with status legend and quick actions

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Edit file
assets\language\en.json
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
310        "help_subtitle": "FAQs and support"
311      },
312      "dashboard": {
313 +      "loading": "Loading your dashboard...",                                                                                                        
314 +      "error_title": "Something Went Wrong",                                                                                                         
315 +      "error_retry": "Retry",                                                                                                                        
316 +      "todays_overview": "Today's Overview",                                                                                                         
317        "revenue": "Today's Revenue",
318        "appointments": "Appointments",
319        "appointments_today": "{} Today",
320        "new_clients": "New Clients",
321        "clients_week": "{} This Week",
322 +      "occupancy": "Occupancy",                                                                                                                      
323 +      "occupancy_rate": "{}%",                                                                                                                       
324        "promotions": "Promotions",
325        "promotions_desc": "Boost Sales",
326        "upcoming": "Upcoming Appointments",
327 +      "upcoming_count": "{} upcoming",                                                                                                               
328 +      "no_upcoming": "No upcoming appointments",                                                                                                     
329 +      "no_upcoming_desc": "No bookings scheduled for the next 7 days",                                                                               
330        "manage_salon": "Manage Salon Profile",
331 -      "manage_salon_desc": "Edit photos, hours, contact info & more"                                                                                 
331 +      "manage_salon_desc": "Edit photos, hours, contact info & more",
332 +      "greeting_morning": "Good Morning",                                                                                                            
333 +      "greeting_afternoon": "Good Afternoon",                                                                                                        
334 +      "greeting_evening": "Good Evening",                                                                                                            
335 +      "notifications_coming_soon": "Notifications coming soon!",                                                                                     
336 +      "services_count": "{} service(s)",                                                                                                             
337 +      "view_schedule": "View Full Schedule"                                                                                                          
338      },
339      "calendar": {
340        "title": "My Schedule",
341 +      "week_view": "Week View",                                                                                                                      
342 +      "month_view": "Month View",                                                                                                                    
343        "list_header": "Appointments for {}",
344        "no_appointments": "No Appointments",
345        "no_appointments_msg": "No appointments scheduled for this day.",
346 -      "services_count": "service(s)"                                                                                                                 
346 +      "services_count": "service(s)",
347 +      "appointment_details": "Appointment Details",                                                                                                  
348 +      "client_section": "Client",                                                                                                                    
349 +      "date_time_section": "Date & Time",                                                                                                            
350 +      "services_section": "Services Booked",                                                                                                         
351 +      "status_section": "Status",                                                                                                                    
352 +      "no_services_found": "No services found",                                                                                                      
353 +      "total_label": "Total: {}",                                                                                                                    
354 +      "minutes_label": "{} minutes",                                                                                                                 
355 +      "mark_complete": "Mark Complete",                                                                                                              
356 +      "mark_complete_title": "Mark as Complete",                                                                                                     
357 +      "mark_complete_confirm": "Are you sure you want to mark this appointment as completed?",                                                       
358 +      "mark_complete_success": "Appointment marked as completed",                                                                                    
359 +      "cancel_title": "Cancel Appointment",                                                                                                          
360 +      "cancel_confirm": "Are you sure you want to cancel this appointment? This action cannot be undone.",                                           
361 +      "cancel_keep": "No, Keep It",                                                                                                                  
362 +      "cancel_yes": "Yes, Cancel",                                                                                                                   
363 +      "cancel_success": "Appointment cancelled",                                                                                                     
364 +      "unknown_client": "Unknown Client",                                                                                                            
365 +      "status_confirmed": "Confirmed",                                                                                                               
366 +      "status_completed": "Completed",                                                                                                               
367 +      "status_cancelled": "Cancelled",                                                                                                               
368 +      "status_pending_payment": "Pending Payment",                                                                                                   
369 +      "status_no_show": "No Show",                                                                                                                   
370 +      "status_payment_failed": "Payment Failed"                                                                                                      
371      },
372      "services": {
373        "title": "Manage Services",
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
Do you want to make this edit to en.json?
1. Yes
   ❯ 2. Yes, allow all edits during this session (meta+m)
3. No

Esc to cancel

▐▛███▜▌   Claude Code v2.1.34
▝▜█████▛▘  Opus 4.6 · Claude Pro
▘▘ ▝▝    D:\A.Projects\pendeza

↑ Install the PyCharm plugin from the JetBrains Marketplace: https://docs.claude.com/s/claude-code-jetbrains

❯ You  enhanced   dashboard,   calender  But Also  ensure  No  Localization  error  I  see  some  jey  missing  like  owner.dashboard.loading              
owner.dashboard.error_title                                                                                                                              
owner.dashboard.todays_overview  So  inshort  ensure  that  the  Owner  side  user  role  UI/UX  is  very  pro  and  Industry  level

● Let me start by exploring the current state of the owner side - dashboard, calendar, and localization files.

● Explore(Explore owner side codebase)
⎿  Done (24 tool uses · 94.1k tokens · 2m 10s)

● Now let me read the key files I need to modify directly.

● Read 4 files (ctrl+o to expand)

● Now let me read the remaining widget files and the dashboard header.

● Read 4 files (ctrl+o to expand)

● Now I have a complete picture. Let me create tasks and start working on all the fixes.

● Starting with the localization keys. I need to add all missing keys for the owner dashboard, calendar, and all hardcoded strings across the widgets.

● Update(assets\language\en.json)
⎿  Added 43 lines, removed 2 lines
310        "help_subtitle": "FAQs and support"                                                                                                
311      },                                                                                                                                   
312      "dashboard": {                                                                                                                       
313 +      "loading": "Loading your dashboard...",                                                                                            
314 +      "error_title": "Something Went Wrong",                                                                                             
315 +      "error_retry": "Retry",                                                                                                            
316 +      "todays_overview": "Today's Overview",                                                                                             
317        "revenue": "Today's Revenue",                                                                                                      
318        "appointments": "Appointments",                                                                                                                 319        "appointments_today": "{} Today",                                                                                                  
320        "new_clients": "New Clients",                                                                                                             
321        "clients_week": "{} This Week",                                                                                                    
322 +      "occupancy": "Occupancy",                                                                                                          
323 +      "occupancy_rate": "{}%",                                                                                                                  
324        "promotions": "Promotions",
325        "promotions_desc": "Boost Sales",
326        "upcoming": "Upcoming Appointments",
327 +      "upcoming_count": "{} upcoming",                                                                                                          
328 +      "no_upcoming": "No upcoming appointments",                                                                                                
329 +      "no_upcoming_desc": "No bookings scheduled for the next 7 days",                                                                          
330        "manage_salon": "Manage Salon Profile",
331 -      "manage_salon_desc": "Edit photos, hours, contact info & more"                                                                            
331 +      "manage_salon_desc": "Edit photos, hours, contact info & more",                                                                           
332 +      "greeting_morning": "Good Morning",                                                                                                       
333 +      "greeting_afternoon": "Good Afternoon",                                                                                                   
334 +      "greeting_evening": "Good Evening",                                                                                                       
335 +      "notifications_coming_soon": "Notifications coming soon!",                                                                                
336 +      "services_count": "{} service(s)",                                                                                                        
337 +      "view_schedule": "View Full Schedule"                                                                                                     
338      },
339      "calendar": {
340        "title": "My Schedule",
341 +      "week_view": "Week View",                                                                                                                 
342 +      "month_view": "Month View",                                                                                                               
343        "list_header": "Appointments for {}",
344        "no_appointments": "No Appointments",
345        "no_appointments_msg": "No appointments scheduled for this day.",
346 -      "services_count": "service(s)"                                                                                                            
346 +      "services_count": "service(s)",                                                                                                           
347 +      "appointment_details": "Appointment Details",                                                                                             
348 +      "client_section": "Client",                                                                                                               
349 +      "date_time_section": "Date & Time",                                                                                                       
350 +      "services_section": "Services Booked",                                                                                                    
351 +      "status_section": "Status",                                                                                                               
352 +      "no_services_found": "No services found",                                                                                                 
353 +      "total_label": "Total: {}",                                                                                                               
354 +      "minutes_label": "{} minutes",                                                                                                            
355 +      "mark_complete": "Mark Complete",                                                                                                         
356 +      "mark_complete_title": "Mark as Complete",                                                                                                
357 +      "mark_complete_confirm": "Are you sure you want to mark this appointment as completed?",                                                  
358 +      "mark_complete_success": "Appointment marked as completed",                                                                               
359 +      "cancel_title": "Cancel Appointment",                                                                                                     
360 +      "cancel_confirm": "Are you sure you want to cancel this appointment? This action cannot be undone.",                                      
361 +      "cancel_keep": "No, Keep It",                                                                                                             
362 +      "cancel_yes": "Yes, Cancel",                                                                                                              
363 +      "cancel_success": "Appointment cancelled",                                                                                                
364 +      "unknown_client": "Unknown Client",                                                                                                       
365 +      "status_confirmed": "Confirmed",                                                                                                          
366 +      "status_completed": "Completed",                                                                                                          
367 +      "status_cancelled": "Cancelled",                                                                                                          
368 +      "status_pending_payment": "Pending Payment",                                                                                              
369 +      "status_no_show": "No Show",                                                                                                              
370 +      "status_payment_failed": "Payment Failed"                                                                                                 
371      },
372      "services": {
373        "title": "Manage Services",

● Update(assets\language\sw.json)                   
⎿  Added 43 lines, removed 2 lines                       
310        "help_subtitle": "Maswali na msaada"                                                                                               
311      },                                                                                                                                   
312      "dashboard": {                                                                                                                       
313 +      "loading": "Inapakia dashibodi yako...",                                                                                           
314 +      "error_title": "Kuna Tatizo",                                                                                                      
315 +      "error_retry": "Jaribu Tena",                                                                                                      
316 +      "todays_overview": "Muhtasari wa Leo",                                                                                                          317        "revenue": "Mapato ya Leo",                                                                                                        
318        "appointments": "Miadi",                                                                                                                  
319        "appointments_today": "{} Leo",                                                                                                    
320        "new_clients": "Wateja Wapya",
321        "clients_week": "{} Wiki Hii",
322 +      "occupancy": "Utumiaji",                                                                                                                  
323 +      "occupancy_rate": "{}%",                                                                                                                  
324        "promotions": "Matangazo",
325        "promotions_desc": "Ongeza Mauzo",
326        "upcoming": "Miadi Ijayo",
327 +      "upcoming_count": "Miadi {} ijayo",                                                                                                       
328 +      "no_upcoming": "Hakuna miadi ijayo",                                                                                                      
329 +      "no_upcoming_desc": "Hakuna miadi iliyopangwa kwa siku 7 zijazo",                                                                         
330        "manage_salon": "Simamia Wasifu wa Saluni",
331 -      "manage_salon_desc": "Badili picha, saa, mawasiliano na zaidi"                                                                            
331 +      "manage_salon_desc": "Badili picha, saa, mawasiliano na zaidi",                                                                           
332 +      "greeting_morning": "Habari ya Asubuhi",                                                                                                  
333 +      "greeting_afternoon": "Habari ya Mchana",                                                                                                 
334 +      "greeting_evening": "Habari ya Jioni",                                                                                                    
335 +      "notifications_coming_soon": "Arifa zinakuja hivi karibuni!",                                                                             
336 +      "services_count": "Huduma {}",                                                                                                            
337 +      "view_schedule": "Angalia Ratiba Kamili"                                                                                                  
338      },
339      "calendar": {
340        "title": "Ratiba Yangu",
341 +      "week_view": "Mtazamo wa Wiki",                                                                                                           
342 +      "month_view": "Mtazamo wa Mwezi",                                                                                                         
343        "list_header": "Miadi ya {}",
344        "no_appointments": "Hakuna Miadi",
345        "no_appointments_msg": "Hakuna miadi iliyopangwa kwa siku hii.",
346 -      "services_count": "huduma"                                                                                                                
346 +      "services_count": "huduma",                                                                                                               
347 +      "appointment_details": "Maelezo ya Miadi",                                                                                                
348 +      "client_section": "Mteja",                                                                                                                
349 +      "date_time_section": "Tarehe na Muda",                                                                                                    
350 +      "services_section": "Huduma Zilizowekwa",                                                                                                 
351 +      "status_section": "Hali",                                                                                                                 
352 +      "no_services_found": "Hakuna huduma zilizopatikana",                                                                                      
353 +      "total_label": "Jumla: {}",                                                                                                               
354 +      "minutes_label": "Dakika {}",                                                                                                             
355 +      "mark_complete": "Weka Imekamilika",                                                                                                      
356 +      "mark_complete_title": "Weka Imekamilika",                                                                                                
357 +      "mark_complete_confirm": "Una uhakika unataka kuweka miadi hii kama imekamilika?",                                                        
358 +      "mark_complete_success": "Miadi imewekwa imekamilika",                                                                                    
359 +      "cancel_title": "Ghairi Miadi",                                                                                                           
360 +      "cancel_confirm": "Una uhakika unataka kughairi miadi hii? Hatua hii haiwezi kubatilishwa.",                                              
361 +      "cancel_keep": "Hapana, Weka",                                                                                                            
362 +      "cancel_yes": "Ndiyo, Ghairi",                                                                                                            
363 +      "cancel_success": "Miadi imeghairiwa",                                                                                                    
364 +      "unknown_client": "Mteja Asiyejulikana",                                                                                                  
365 +      "status_confirmed": "Imethibitishwa",                                                                                                     
366 +      "status_completed": "Imekamilika",                                                                                                        
367 +      "status_cancelled": "Imeghairiwa",                                                                                                        
368 +      "status_pending_payment": "Inasubiri Malipo",                                                                                             
369 +      "status_no_show": "Hakuja",                                                                                                               
370 +      "status_payment_failed": "Malipo Yameshindwa"                                                                                             
371      },
372      "services": {
373        "title": "Simamia Huduma",

● Now localizing the dashboard header.

● Write(lib\features\3_owner_management\dashboard\presentation\widgets\dashboard_header.dart)
⎿  Added 248 lines, removed 247 lines                             
1 -import 'package:flutter/material.dart';                                                                                                 
2 -import 'package:flutter/cupertino.dart';                                                                                                
3 -import 'package:flutter_bloc/flutter_bloc.dart';                                                                                        
4 -import 'package:pendeza/app/config/theme/app_constants.dart';                                                                           
5 -import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';                                                                              6 -import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';                                                             
7 -import 'package:pendeza/shared/widgets/profile_avatar.dart';                                                                                            8 -                                                                                                                                        
9 -class DashboardHeader extends StatelessWidget {                                                                                                 
10 -  final String salonName;                                                                                                               
11 -                                                                                                                                        
12 -  const DashboardHeader({                                                                                                                       
13 -    super.key,                                                                                                                                  
14 -    required this.salonName,                                                                                                                    
15 -  });                                                                                                                                           
16 -                                                                                                                                                
17 -  String _getGreeting() {                                                                                                                       
18 -    final hour = DateTime.now().hour;                                                                                                           
19 -    if (hour < 12) return 'Good Morning';                                                                                                       
20 -    if (hour < 17) return 'Good Afternoon';                                                                                                     
21 -    return 'Good Evening';                                                                                                                      
22 -  }                                                                                                                                             
23 -                                                                                                                                                
24 -  @override                                                                                                                                     
25 -  Widget build(BuildContext context) {                                                                                                          
26 -    final theme = Theme.of(context);                                                                                                            
27 -    final authState = context.watch<AuthBloc>().state;                                                                                          
28 -                                                                                                                                                
29 -    String ownerName = 'Owner';                                                                                                                 
30 -    String? imageUrl;                                                                                                                           
31 -                                                                                                                                                
32 -    if (authState is Authenticated) {                                                                                                           
33 -      ownerName = authState.user.fullName.split(' ').first;                                                                                     
34 -      imageUrl = authState.user.profilePictureUrl;                                                                                              
35 -    }                                                                                                                                           
36 -                                                                                                                                                
37 -    return Container(                                                                                                                           
38 -      padding: const EdgeInsets.all(AppConstants.padM),  // Reduced from padL (16->12) if needed, but kept same                                 
39 -      decoration: BoxDecoration(                                                                                                                
40 -        gradient: LinearGradient(                                                                                                               
41 -          begin: Alignment.topLeft,                                                                                                             
42 -          end: Alignment.bottomRight,                                                                                                           
43 -          colors: [                                                                                                                             
44 -            theme.colorScheme.primary.withValues(alpha: 0.08),                                                                                  
45 -            theme.colorScheme.secondary.withValues(alpha: 0.05),                                                                                
46 -          ],                                                                                                                                    
47 -        ),                                                                                                                                      
48 -        borderRadius: BorderRadius.circular(24),                                                                                                
49 -        border: Border.all(                                                                                                                     
50 -          color: theme.colorScheme.primary.withValues(alpha: 0.1),                                                                              
51 -        ),                                                                                                                                      
52 -        boxShadow: [                                                                                                                            
53 -          BoxShadow(                                                                                                                            
54 -            color: theme.colorScheme.primary.withValues(alpha: 0.08),                                                                           
55 -            blurRadius: 20,                                                                                                                     
56 -            offset: const Offset(0, 4),                                                                                                         
57 -          ),                                                                                                                                    
58 -        ],                                                                                                                                      
59 -      ),                                                                                                                                        
60 -      child: Row(                                                                                                                               
61 -        children: [                                                                                                                             
62 -          // Avatar with gradient border                                                                                                        
63 -          Container(                                                                                                                            
64 -            decoration: BoxDecoration(                                                                                                          
65 -              shape: BoxShape.circle,                                                                                                           
66 -              gradient: LinearGradient(                                                                                                         
67 -                colors: [                                                                                                                       
68 -                  theme.colorScheme.primary,                                                                                                    
69 -                  theme.colorScheme.secondary,                                                                                                  
70 -                ],                                                                                                                              
71 -              ),                                                                                                                                
72 -              boxShadow: [                                                                                                                      
73 -                BoxShadow(                                                                                                                      
74 -                  color: theme.colorScheme.primary.withValues(alpha: 0.3),                                                                      
75 -                  blurRadius: 12,                                                                                                               
76 -                  offset: const Offset(0, 4),                                                                                                   
77 -                ),                                                                                                                              
78 -              ],                                                                                                                                
79 -            ),                                                                                                                                  
80 -            padding: const EdgeInsets.all(3),                                                                                                   
81 -            child: ProfileAvatar(                                                                                                               
82 -              fullName: ownerName,                                                                                                              
83 -              imageUrl: imageUrl,                                                                                                               
84 -              radius: 28,                                                                                                                       
85 -            ),                                                                                                                                  
86 -          ),                                                                                                                                    
87 -          const SizedBox(width: AppConstants.padM),                                                                                             
88 -                                                                                                                                                
89 -          // Text content                                                                                                                       
90 -          Expanded(                                                                                                                             
91 -            child: Column(                                                                                                                      
92 -              crossAxisAlignment: CrossAxisAlignment.start,                                                                                     
93 -              children: [                                                                                                                       
94 -                Text(                                                                                                                           
95 -                  _getGreeting(),                                                                                                               
96 -                  style: theme.textTheme.bodyMedium?.copyWith(                                                                                  
97 -                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),                                                                  
98 -                    fontSize: 14,  // Slightly reduced if needed                                                                                
99 -                  ),                                                                                                                            
100 -                  maxLines: 1,                                                                                                                  
101 -                  overflow: TextOverflow.ellipsis,                                                                                              
102 -                ),                                                                                                                              
103 -                const SizedBox(height: 4),                                                                                                      
104 -                Row(                                                                                                                            
105 -                  children: [                                                                                                                   
106 -                    Flexible(                                                                                                                   
107 -                      child: Text(                                                                                                              
108 -                        ownerName,                                                                                                              
109 -                        style: theme.textTheme.headlineSmall?.copyWith(                                                                         
110 -                          fontWeight: FontWeight.bold,                                                                                          
111 -                          fontSize: 18,  // Slightly reduced if overflow is severe                                                              
112 -                        ),                                                                                                                      
113 -                        maxLines: 1,                                                                                                            
114 -                        overflow: TextOverflow.ellipsis,                                                                                        
115 -                      ),                                                                                                                        
116 -                    ),                                                                                                                          
117 -                    const SizedBox(width: 4),                                                                                                   
118 -                    TweenAnimationBuilder<double>(                                                                                              
119 -                      tween: Tween(begin: 0.0, end: 1.0),                                                                                       
120 -                      duration: const Duration(milliseconds: 600),                                                                              
121 -                      curve: Curves.elasticOut,                                                                                                 
122 -                      builder: (context, value, child) {                                                                                        
123 -                        return Transform.scale(                                                                                                 
124 -                          scale: value,                                                                                                         
125 -                          child: Text(                                                                                                          
126 -                            '👋',                                                                                                               
127 -                            style: TextStyle(fontSize: 20 * value),                                                                     
128 -                          ),                                                                                                                    
129 -                        );                                                                                                                      
130 -                      },                                                                                                                        
131 -                    ),                                                                                                                          
132 -                  ],                                                                                                                            
133 -                ),                                                                                                                              
134 -                const SizedBox(height: 2),                                                                                                      
135 -                Row(                                                                                                                            
136 -                  children: [                                                                                                                   
137 -                    Flexible(  // Wrapped in Flexible to prevent overflow                                                                       
138 -                      child: Container(                                                                                                         
139 -                        padding: const EdgeInsets.symmetric(                                                                                    
140 -                          horizontal: 8,                                                                                                        
141 -                          vertical: 4,                                                                                                          
142 -                        ),                                                                                                                      
143 -                        decoration: BoxDecoration(                                                                                              
144 -                          gradient: LinearGradient(                                                                                             
145 -                            colors: [                                                                                                           
146 -                              theme.colorScheme.primary.withValues(alpha: 0.15),                                                                
147 -                              theme.colorScheme.secondary.withValues(alpha: 0.15),                                                              
148 -                            ],                                                                                                                  
149 -                          ),                                                                                                                    
150 -                          borderRadius: BorderRadius.circular(8),                                                                               
151 -                          border: Border.all(                                                                                                   
152 -                            color: theme.colorScheme.primary.withValues(alpha: 0.3),                                                            
153 -                          ),                                                                                                                    
154 -                        ),                                                                                                                      
155 -                        child: Row(                                                                                                             
156 -                          mainAxisSize: MainAxisSize.min,                                                                                       
157 -                          children: [                                                                                                           
158 -                            Icon(                                                                                                               
159 -                              CupertinoIcons.building_2_fill,                                                                                   
160 -                              size: 12,                                                                                                         
161 -                              color: theme.colorScheme.primary,                                                                                 
162 -                            ),                                                                                                                  
163 -                            const SizedBox(width: 4),                                                                                           
164 -                            Flexible(                                                                                                           
165 -                              child: Text(                                                                                                      
166 -                                salonName,                                                                                                      
167 -                                style: theme.textTheme.bodySmall?.copyWith(                                                                     
168 -                                  color: theme.colorScheme.primary,                                                                             
169 -                                  fontWeight: FontWeight.w600,                                                                                  
170 -                                  fontSize: 12,  // Reduced slightly                                                                            
171 -                                ),                                                                                                              
172 -                                maxLines: 1,                                                                                                    
173 -                                overflow: TextOverflow.ellipsis,                                                                                
174 -                              ),                                                                                                                
175 -                            ),                                                                                                                  
176 -                          ],                                                                                                                    
177 -                        ),                                                                                                                      
178 -                      ),                                                                                                                        
179 -                    ),                                                                                                                          
180 -                  ],                                                                                                                            
181 -                ),                                                                                                                              
182 -              ],                                                                                                                                
183 -            ),                                                                                                                                  
184 -          ),                                                                                                                                    
185 -                                                                                                                                                
186 -          // Notification button                                                                                                                
187 -          Container(                                                                                                                            
188 -            decoration: BoxDecoration(                                                                                                          
189 -              color: theme.colorScheme.surface,                                                                                                 
190 -              shape: BoxShape.circle,                                                                                                           
191 -              boxShadow: [                                                                                                                      
192 -                BoxShadow(                                                                                                                      
193 -                  color: Colors.black.withValues(alpha: 0.05),                                                                                  
194 -                  blurRadius: 8,                                                                                                                
195 -                  offset: const Offset(0, 2),                                                                                                   
196 -                ),                                                                                                                              
197 -              ],                                                                                                                                
198 -            ),                                                                                                                                  
199 -            child: Stack(                                                                                                                       
200 -              clipBehavior: Clip.none,                                                                                                          
201 -              children: [                                                                                                                       
202 -                IconButton(                                                                                                                     
203 -                  onPressed: () {                                                                                                               
204 -                    ScaffoldMessenger.of(context).showSnackBar(                                                                                 
205 -                      const SnackBar(                                                                                                           
206 -                        content: Text('Notifications coming soon!'),                                                                            
207 -                        duration: Duration(seconds: 2),                                                                                         
208 -                      ),                                                                                                                        
209 -                    );                                                                                                                          
210 -                  },                                                                                                                            
211 -                  icon: Icon(                                                                                                                   
212 -                    CupertinoIcons.bell,                                                                                                        
213 -                    color: theme.colorScheme.onSurface,                                                                                         
214 -                  ),                                                                                                                            
215 -                ),                                                                                                                              
216 -                Positioned(                                                                                                                     
217 -                  top: 8,                                                                                                                       
218 -                  right: 8,                                                                                                                     
219 -                  child: Container(                                                                                                             
220 -                    width: 10,                                                                                                                  
221 -                    height: 10,                                                                                                                 
222 -                    decoration: BoxDecoration(                                                                                                  
223 -                      gradient: const LinearGradient(                                                                                           
224 -                        colors: [Colors.red, Colors.orange],                                                                                    
225 -                      ),                                                                                                                        
226 -                      shape: BoxShape.circle,                                                                                                   
227 -                      border: Border.all(                                                                                                       
228 -                        color: theme.scaffoldBackgroundColor,                                                                                   
229 -                        width: 2,                                                                                                               
230 -                      ),                                                                                                                        
231 -                      boxShadow: [                                                                                                              
232 -                        BoxShadow(                                                                                                              
233 -                          color: Colors.red.withValues(alpha: 0.5),                                                                             
234 -                          blurRadius: 4,                                                                                                        
235 -                        ),                                                                                                                      
236 -                      ],                                                                                                                        
237 -                    ),                                                                                                                          
238 -                  ),                                                                                                                            
239 -                ),                                                                                                                              
240 -              ],                                                                                                                                
241 -            ),                                                                                                                                  
242 -          ),                                                                                                                                    
243 -        ],                                                                                                                                      
244 -      ),                                                                                                                                        
245 -    );                                                                                                                                          
246 -  }                                                                                                                                             
247 -}                                                                                                                                               
1   No newline at end of file
2 +import 'package:easy_localization/easy_localization.dart';                                                                                      
3 +import 'package:flutter/material.dart';                                                                                                         
4 +import 'package:flutter/cupertino.dart';                                                                                                        
5 +import 'package:flutter_bloc/flutter_bloc.dart';                                                                                                
6 +import 'package:pendeza/app/config/theme/app_constants.dart';                                                                                   
7 +import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';                                                                      
8 +import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';                                                                     
9 +import 'package:pendeza/shared/widgets/profile_avatar.dart';                                                                                    
10 +                                                                                                                                                
11 +class DashboardHeader extends StatelessWidget {                                                                                                 
12 +  final String salonName;                                                                                                                       
13 +                                                                                                                                                
14 +  const DashboardHeader({                                                                                                                       
15 +    super.key,                                                                                                                                  
16 +    required this.salonName,                                                                                                                    
17 +  });                                                                                                                                           
18 +                                                                                                                                                
19 +  String _getGreeting() {                                                                                                                       
20 +    final hour = DateTime.now().hour;                                                                                                           
21 +    if (hour < 12) return 'owner.dashboard.greeting_morning'.tr();                                                                              
22 +    if (hour < 17) return 'owner.dashboard.greeting_afternoon'.tr();                                                                            
23 +    return 'owner.dashboard.greeting_evening'.tr();                                                                                             
24 +  }                                                                                                                                             
25 +                                                                                                                                                
26 +  @override                                                                                                                                     
27 +  Widget build(BuildContext context) {                                                                                                          
28 +    final theme = Theme.of(context);                                                                                                            
29 +    final authState = context.watch<AuthBloc>().state;                                                                                          
30 +                                                                                                                                                
31 +    String ownerName = 'Owner';                                                                                                                 
32 +    String? imageUrl;                                                                                                                           
33 +                                                                                                                                                
34 +    if (authState is Authenticated) {                                                                                                           
35 +      ownerName = authState.user.fullName.split(' ').first;                                                                                     
36 +      imageUrl = authState.user.profilePictureUrl;                                                                                              
37 +    }                                                                                                                                           
38 +                                                                                                                                                
39 +    return Container(                                                                                                                           
40 +      padding: const EdgeInsets.all(AppConstants.padM),                                                                                         
41 +      decoration: BoxDecoration(                                                                                                                
42 +        gradient: LinearGradient(                                                                                                               
43 +          begin: Alignment.topLeft,                                                                                                             
44 +          end: Alignment.bottomRight,                                                                                                           
45 +          colors: [                                                                                                                             
46 +            theme.colorScheme.primary.withValues(alpha: 0.08),                                                                                  
47 +            theme.colorScheme.secondary.withValues(alpha: 0.05),                                                                                
48 +          ],                                                                                                                                    
49 +        ),                                                                                                                                      
50 +        borderRadius: BorderRadius.circular(24),                                                                                                
51 +        border: Border.all(                                                                                                                     
52 +          color: theme.colorScheme.primary.withValues(alpha: 0.1),                                                                              
53 +        ),                                                                                                                                      
54 +        boxShadow: [                                                                                                                            
55 +          BoxShadow(                                                                                                                            
56 +            color: theme.colorScheme.primary.withValues(alpha: 0.08),                                                                           
57 +            blurRadius: 20,                                                                                                                     
58 +            offset: const Offset(0, 4),                                                                                                         
59 +          ),                                                                                                                                    
60 +        ],                                                                                                                                      
61 +      ),                                                                                                                                        
62 +      child: Row(                                                                                                                               
63 +        children: [                                                                                                                             
64 +          // Avatar with gradient border                                                                                                        
65 +          Container(                                                                                                                            
66 +            decoration: BoxDecoration(                                                                                                          
67 +              shape: BoxShape.circle,                                                                                                           
68 +              gradient: LinearGradient(                                                                                                         
69 +                colors: [                                                                                                                       
70 +                  theme.colorScheme.primary,                                                                                                    
71 +                  theme.colorScheme.secondary,                                                                                                  
72 +                ],                                                                                                                              
73 +              ),                                                                                                                                
74 +              boxShadow: [                                                                                                                      
75 +                BoxShadow(                                                                                                                      
76 +                  color: theme.colorScheme.primary.withValues(alpha: 0.3),                                                                      
77 +                  blurRadius: 12,                                                                                                               
78 +                  offset: const Offset(0, 4),                                                                                                   
79 +                ),                                                                                                                              
80 +              ],                                                                                                                                
81 +            ),                                                                                                                                  
82 +            padding: const EdgeInsets.all(3),                                                                                                   
83 +            child: ProfileAvatar(                                                                                                               
84 +              fullName: ownerName,                                                                                                              
85 +              imageUrl: imageUrl,                                                                                                               
86 +              radius: 28,                                                                                                                       
87 +            ),                                                                                                                                  
88 +          ),                                                                                                                                    
89 +          const SizedBox(width: AppConstants.padM),                                                                                             
90 +                                                                                                                                                
91 +          // Text content                                                                                                                       
92 +          Expanded(                                                                                                                             
93 +            child: Column(                                                                                                                      
94 +              crossAxisAlignment: CrossAxisAlignment.start,                                                                                     
95 +              children: [                                                                                                                       
96 +                Text(                                                                                                                           
97 +                  _getGreeting(),                                                                                                               
98 +                  style: theme.textTheme.bodyMedium?.copyWith(                                                                                  
99 +                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),                                                                  
100 +                    fontSize: 14,                                                                                                               
101 +                  ),                                                                                                                            
102 +                  maxLines: 1,                                                                                                                  
103 +                  overflow: TextOverflow.ellipsis,                                                                                              
104 +                ),                                                                                                                              
105 +                const SizedBox(height: 4),                                                                                                      
106 +                Row(                                                                                                                            
107 +                  children: [                                                                                                                   
108 +                    Flexible(                                                                                                                   
109 +                      child: Text(                                                                                                              
110 +                        ownerName,                                                                                                              
111 +                        style: theme.textTheme.headlineSmall?.copyWith(                                                                         
112 +                          fontWeight: FontWeight.bold,                                                                                          
113 +                          fontSize: 18,                                                                                                         
114 +                        ),                                                                                                                      
115 +                        maxLines: 1,                                                                                                            
116 +                        overflow: TextOverflow.ellipsis,                                                                                        
117 +                      ),                                                                                                                        
118 +                    ),                                                                                                                          
119 +                    const SizedBox(width: 4),                                                                                                   
120 +                    TweenAnimationBuilder<double>(                                                                                              
121 +                      tween: Tween(begin: 0.0, end: 1.0),                                                                                       
122 +                      duration: const Duration(milliseconds: 600),                                                                              
123 +                      curve: Curves.elasticOut,                                                                                                 
124 +                      builder: (context, value, child) {                                                                                        
125 +                        return Transform.scale(                                                                                                 
126 +                          scale: value,                                                                                                         
127 +                          child: Text(                                                                                                          
128 +                            '\u{1F44B}',                                                                                                        
129 +                            style: TextStyle(fontSize: 20 * value),                                                                             
130 +                          ),                                                                                                                    
131 +                        );                                                                                                                      
132 +                      },                                                                                                                        
133 +                    ),                                                                                                                          
134 +                  ],                                                                                                                            
135 +                ),                                                                                                                              
136 +                const SizedBox(height: 2),                                                                                                      
137 +                Row(                                                                                                                            
138 +                  children: [                                                                                                                   
139 +                    Flexible(                                                                                                                   
140 +                      child: Container(                                                                                                         
141 +                        padding: const EdgeInsets.symmetric(                                                                                    
142 +                          horizontal: 8,                                                                                                        
143 +                          vertical: 4,                                                                                                          
144 +                        ),                                                                                                                      
145 +                        decoration: BoxDecoration(                                                                                              
146 +                          gradient: LinearGradient(                                                                                             
147 +                            colors: [                                                                                                           
148 +                              theme.colorScheme.primary.withValues(alpha: 0.15),                                                                
149 +                              theme.colorScheme.secondary.withValues(alpha: 0.15),                                                              
150 +                            ],                                                                                                                  
151 +                          ),                                                                                                                    
152 +                          borderRadius: BorderRadius.circular(8),                                                                               
153 +                          border: Border.all(                                                                                                   
154 +                            color: theme.colorScheme.primary.withValues(alpha: 0.3),                                                            
155 +                          ),                                                                                                                    
156 +                        ),                                                                                                                      
157 +                        child: Row(                                                                                                             
158 +                          mainAxisSize: MainAxisSize.min,                                                                                       
159 +                          children: [                                                                                                           
160 +                            Icon(                                                                                                               
161 +                              CupertinoIcons.building_2_fill,                                                                                   
162 +                              size: 12,                                                                                                         
163 +                              color: theme.colorScheme.primary,                                                                                 
164 +                            ),                                                                                                                  
165 +                            const SizedBox(width: 4),                                                                                           
166 +                            Flexible(                                                                                                           
167 +                              child: Text(                                                                                                      
168 +                                salonName,                                                                                                      
169 +                                style: theme.textTheme.bodySmall?.copyWith(                                                                     
170 +                                  color: theme.colorScheme.primary,                                                                             
171 +                                  fontWeight: FontWeight.w600,                                                                                  
172 +                                  fontSize: 12,                                                                                                 
173 +                                ),                                                                                                              
174 +                                maxLines: 1,                                                                                                    
175 +                                overflow: TextOverflow.ellipsis,                                                                                
176 +                              ),                                                                                                                
177 +                            ),                                                                                                                  
178 +                          ],                                                                                                                    
179 +                        ),                                                                                                                      
180 +                      ),                                                                                                                        
181 +                    ),                                                                                                                          
182 +                  ],                                                                                                                            
183 +                ),                                                                                                                              
184 +              ],                                                                                                                                
185 +            ),                                                                                                                                  
186 +          ),                                                                                                                                    
187 +                                                                                                                                                
188 +          // Notification button                                                                                                                
189 +          Container(                                                                                                                            
190 +            decoration: BoxDecoration(                                                                                                          
191 +              color: theme.colorScheme.surface,                                                                                                 
192 +              shape: BoxShape.circle,                                                                                                           
193 +              boxShadow: [                                                                                                                      
194 +                BoxShadow(                                                                                                                      
195 +                  color: Colors.black.withValues(alpha: 0.05),                                                                                  
196 +                  blurRadius: 8,                                                                                                                
197 +                  offset: const Offset(0, 2),                                                                                                   
198 +                ),                                                                                                                              
199 +              ],                                                                                                                                
200 +            ),                                                                                                                                  
201 +            child: Stack(                                                                                                                       
202 +              clipBehavior: Clip.none,                                                                                                          
203 +              children: [                                                                                                                       
204 +                IconButton(                                                                                                                     
205 +                  onPressed: () {                                                                                                               
206 +                    ScaffoldMessenger.of(context).showSnackBar(                                                                                 
207 +                      SnackBar(                                                                                                                 
208 +                        content: Text('owner.dashboard.notifications_coming_soon'.tr()),                                                        
209 +                        duration: const Duration(seconds: 2),                                                                                   
210 +                      ),                                                                                                                        
211 +                    );                                                                                                                          
212 +                  },                                                                                                                            
213 +                  icon: Icon(                                                                                                                   
214 +                    CupertinoIcons.bell,                                                                                                        
215 +                    color: theme.colorScheme.onSurface,                                                                                         
216 +                  ),                                                                                                                            
217 +                ),                                                                                                                              
218 +                Positioned(                                                                                                              
219 +                  top: 8,                                                                                                                       
220 +                  right: 8,                                                                                                                     
221 +                  child: Container(                                                                                                             
222 +                    width: 10,                                                                                                                  
223 +                    height: 10,                                                                                                                 
224 +                    decoration: BoxDecoration(                                                                                                  
225 +                      gradient: const LinearGradient(                                                                                           
226 +                        colors: [Colors.red, Colors.orange],                                                                                    
227 +                      ),                                                                                                                        
228 +                      shape: BoxShape.circle,                                                                                                   
229 +                      border: Border.all(                                                                                                       
230 +                        color: theme.scaffoldBackgroundColor,                                                                                   
231 +                        width: 2,                                                                                                               
232 +                      ),                                                                                                                        
233 +                      boxShadow: [                                                                                                              
234 +                        BoxShadow(                                                                                                              
235 +                          color: Colors.red.withValues(alpha: 0.5),                                                                             
236 +                          blurRadius: 4,                                                                                                        
237 +                        ),                                                                                                                      
238 +                      ],                                                                                                                        
239 +                    ),                                                                                                                          
240 +                  ),                                                                                                                            
241 +                ),                                                                                                                              
242 +              ],                                                                                                                                
243 +            ),                                                                                                                                  
244 +          ),                                                                                                                                    
245 +        ],                                                                                                                                      
246 +      ),                                                                                                                                        
247 +    );                                                                                                                                          
248 +  }                                                                                                                                             
249 +}

● Now localizing the upcoming appointments list.

● Write(lib\features\3_owner_management\dashboard\presentation\widgets\upcoming_appointments_list.dart)
⎿  Added 371 lines, removed 370 lines                             
1 -import 'package:flutter/material.dart';                                                                                                 
2 -import 'package:flutter/cupertino.dart';                                                                                                
3 -import 'package:intl/intl.dart';                                                                                                        
4 -import 'package:pendeza/app/config/theme/app_constants.dart';                                                                           
5 -import 'package:pendeza/app/services/firestore_service.dart';                                                                                           6 -import 'package:pendeza/app/services/service_locator.dart';                                                                             
7 -import 'package:pendeza/shared/models/appointment_model.dart';                                                                                          8 -import 'package:pendeza/shared/widgets/profile_avatar.dart';                                                                            
9 -import '../../../../0_auth/data/models/user_model.dart';                                                                                        
10 -                                                                                                                                        
11 -class UpcomingAppointmentsList extends StatelessWidget {                                                                                
12 -  final List<AppointmentModel> appointments;                                                                                                    
13 -  final VoidCallback? onAppointmentTap;                                                                                                         
14 -                                                                                                                                                
15 -  const UpcomingAppointmentsList({                                                                                                              
16 -    super.key,                                                                                                                                  
17 -    required this.appointments,                                                                                                                 
18 -    this.onAppointmentTap,                                                                                                                      
19 -  });                                                                                                                                           
20 -                                                                                                                                                
21 -  @override                                                                                                                                     
22 -  Widget build(BuildContext context) {                                                                                                          
23 -    final theme = Theme.of(context);                                                                                                            
24 -                                                                                                                                                
25 -    if (appointments.isEmpty) {                                                                                                                 
26 -      return _buildEmptyState(context);                                                                                                         
27 -    }                                                                                                                                           
28 -                                                                                                                                                
29 -    return Column(                                                                                                                              
30 -      crossAxisAlignment: CrossAxisAlignment.start,                                                                                             
31 -      children: [                                                                                                                               
32 -        // Section header with icon                                                                                                             
33 -        Row(                                                                                                                                    
34 -          children: [                                                                                                                           
35 -            Container(                                                                                                                          
36 -              padding: const EdgeInsets.all(8),                                                                                                 
37 -              decoration: BoxDecoration(                                                                                                        
38 -                gradient: LinearGradient(                                                                                                       
39 -                  colors: [                                                                                                                     
40 -                    theme.colorScheme.primary.withValues(alpha: 0.15),                                                                          
41 -                    theme.colorScheme.secondary.withValues(alpha: 0.15),                                                                        
42 -                  ],                                                                                                                            
43 -                ),                                                                                                                              
44 -                borderRadius: BorderRadius.circular(10),                                                                                        
45 -              ),                                                                                                                                
46 -              child: Icon(                                                                                                                      
47 -                CupertinoIcons.calendar_today,                                                                                                  
48 -                color: theme.colorScheme.primary,                                                                                               
49 -                size: 20,                                                                                                                       
50 -              ),                                                                                                                                
51 -            ),                                                                                                                                  
52 -            const SizedBox(width: 12),                                                                                                          
53 -            Text(                                                                                                                               
54 -              'Upcoming Appointments',                                                                                                          
55 -              style: theme.textTheme.titleLarge?.copyWith(                                                                                      
56 -                fontWeight: FontWeight.bold,                                                                                                    
57 -              ),                                                                                                                                
58 -            ),                                                                                                                                  
59 -            const Spacer(),                                                                                                                     
60 -            Container(                                                                                                                          
61 -              padding: const EdgeInsets.symmetric(                                                                                              
62 -                horizontal: 10,                                                                                                                 
63 -                vertical: 4,                                                                                                                    
64 -              ),                                                                                                                                
65 -              decoration: BoxDecoration(                                                                                                        
66 -                gradient: LinearGradient(                                                                                                       
67 -                  colors: [                                                                                                                     
68 -                    theme.colorScheme.primary.withValues(alpha: 0.15),                                                                          
69 -                    theme.colorScheme.secondary.withValues(alpha: 0.15),                                                                        
70 -                  ],                                                                                                                            
71 -                ),                                                                                                                              
72 -                borderRadius: BorderRadius.circular(12),                                                                                        
73 -                border: Border.all(                                                                                                             
74 -                  color: theme.colorScheme.primary.withValues(alpha: 0.3),                                                                      
75 -                ),                                                                                                                              
76 -              ),                                                                                                                                
77 -              child: Text(                                                                                                                      
78 -                '${appointments.length}',                                                                                                       
79 -                style: theme.textTheme.labelMedium?.copyWith(                                                                                   
80 -                  color: theme.colorScheme.primary,                                                                                             
81 -                  fontWeight: FontWeight.bold,                                                                                                  
82 -                ),                                                                                                                              
83 -              ),                                                                                                                                
84 -            ),                                                                                                                                  
85 -          ],                                                                                                                                    
86 -        ),                                                                                                                                      
87 -        const SizedBox(height: AppConstants.padM),                                                                                              
88 -                                                                                                                                                
89 -        // Appointments list with staggered animation                                                                                           
90 -        ...appointments.asMap().entries.map((entry) {                                                                                           
91 -          final index = entry.key;                                                                                                              
92 -          final appointment = entry.value;                                                                                                      
93 -          return TweenAnimationBuilder<double>(                                                                                                 
94 -            tween: Tween(begin: 0.0, end: 1.0),                                                                                                 
95 -            duration: Duration(milliseconds: 300 + (index * 80)),                                                                               
96 -            curve: Curves.easeOutCubic,                                                                                                         
97 -            builder: (context, value, child) {                                                                                                  
98 -              return Opacity(                                                                                                                   
99 -                opacity: value,                                                                                                                 
100 -                child: Transform.translate(                                                                                                     
101 -                  offset: Offset(0, 20 * (1 - value)),                                                                                          
102 -                  child: child,                                                                                                                 
103 -                ),                                                                                                                              
104 -              );                                                                                                                                
105 -            },                                                                                                                                  
106 -            child: _UpcomingAppointmentItem(                                                                                                    
107 -              appointment: appointment,                                                                                                         
108 -              onTap: onAppointmentTap,                                                                                                          
109 -            ),                                                                                                                                  
110 -          );                                                                                                                                    
111 -        }),                                                                                                                                     
112 -      ],                                                                                                                                        
113 -    );                                                                                                                                          
114 -  }                                                                                                                                             
115 -                                                                                                                                                
116 -  Widget _buildEmptyState(BuildContext context) {                                                                                               
117 -    final theme = Theme.of(context);                                                                                                            
118 -                                                                                                                                                
119 -    return Column(                                                                                                                              
120 -      crossAxisAlignment: CrossAxisAlignment.start,                                                                                             
121 -      children: [                                                                                                                               
122 -        // Section header                                                                                                                       
123 -        Row(                                                                                                                                    
124 -          children: [                                                                                                                           
125 -            Container(                                                                                                                          
126 -              padding: const EdgeInsets.all(8),                                                                                                 
127 -              decoration: BoxDecoration(                                                                                                        
128 -                gradient: LinearGradient(                                                                                                       
129 -                  colors: [                                                                                                                     
130 -                    theme.colorScheme.primary.withValues(alpha: 0.15),                                                                          
131 -                    theme.colorScheme.secondary.withValues(alpha: 0.15),                                                                        
132 -                  ],                                                                                                                            
133 -                ),                                                                                                                              
134 -                borderRadius: BorderRadius.circular(10),                                                                                        
135 -              ),                                                                                                                                
136 -              child: Icon(                                                                                                                      
137 -                CupertinoIcons.calendar_today,                                                                                                  
138 -                color: theme.colorScheme.primary,                                                                                               
139 -                size: 20,                                                                                                                       
140 -              ),                                                                                                                                
141 -            ),                                                                                                                                  
142 -            const SizedBox(width: 12),                                                                                                          
143 -            Text(                                                                                                                               
144 -              'Upcoming Appointments',                                                                                                          
145 -              style: theme.textTheme.titleLarge?.copyWith(                                                                                      
146 -                fontWeight: FontWeight.bold,                                                                                                    
147 -              ),                                                                                                                                
148 -            ),                                                                                                                                  
149 -          ],                                                                                                                                    
150 -        ),                                                                                                                                      
151 -        const SizedBox(height: AppConstants.padM),                                                                                              
152 -                                                                                                                                                
153 -        // Empty state                                                                                                                          
154 -        Container(                                                                                                                              
155 -          padding: const EdgeInsets.all(AppConstants.padXL),                                                                                    
156 -          decoration: BoxDecoration(                                                                                                            
157 -            gradient: LinearGradient(                                                                                                           
158 -              colors: [                                                                                                                         
159 -                theme.colorScheme.surfaceContainerHighest,                                                                                      
160 -                theme.colorScheme.surface,                                                                                                      
161 -              ],                                                                                                                                
162 -            ),                                                                                                                                  
163 -            borderRadius: BorderRadius.circular(20),                                                                                            
164 -            border: Border.all(                                                                                                                 
165 -              color: theme.colorScheme.outline.withValues(alpha: 0.1),                                                                          
166 -            ),                                                                                                                                  
167 -          ),                                                                                                                                    
168 -          child: Center(                                                                                                                        
169 -            child: Column(                                                                                                                      
170 -              children: [                                                                                                                       
171 -                Container(                                                                                                                      
172 -                  padding: const EdgeInsets.all(16),                                                                                            
173 -                  decoration: BoxDecoration(                                                                                                    
174 -                    color: theme.colorScheme.primary.withValues(alpha: 0.1),                                                                    
175 -                    shape: BoxShape.circle,                                                                                                     
176 -                  ),                                                                                                                            
177 -                  child: Icon(                                                                                                                  
178 -                    CupertinoIcons.checkmark_alt_circle,                                                                                        
179 -                    size: 48,                                                                                                                   
180 -                    color: theme.colorScheme.primary.withValues(alpha: 0.5),                                                                    
181 -                  ),                                                                                                                            
182 -                ),                                                                                                                              
183 -                const SizedBox(height: AppConstants.padM),                                                                                      
184 -                Text(                                                                                                                           
185 -                  'No upcoming appointments',                                                                                                   
186 -                  style: theme.textTheme.bodyMedium?.copyWith(                                                                                  
187 -                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),                                                                  
188 -                    fontWeight: FontWeight.w500,                                                                                                
189 -                  ),                                                                                                                            
190 -                  textAlign: TextAlign.center,                                                                                                  
191 -                ),                                                                                                                              
192 -                const SizedBox(height: 4),                                                                                                      
193 -                Text(                                                                                                                           
194 -                  'No bookings scheduled for the next 7 days',                                                                                  
195 -                  style: theme.textTheme.bodySmall?.copyWith(                                                                                   
196 -                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),                                                                  
197 -                  ),                                                                                                                            
198 -                  textAlign: TextAlign.center,                                                                                                  
199 -                ),                                                                                                                              
200 -              ],                                                                                                                                
201 -            ),                                                                                                                                  
202 -          ),                                                                                                                                    
203 -        ),                                                                                                                                      
204 -      ],                                                                                                                                        
205 -    );                                                                                                                                          
206 -  }                                                                                                                                             
207 -}                                                                                                                                               
208 -                                                                                                                                                
209 -class _UpcomingAppointmentItem extends StatelessWidget {                                                                                        
210 -  final AppointmentModel appointment;                                                                                                           
211 -  final VoidCallback? onTap;                                                                                                            
212 -                                                                                                                                                
213 -  const _UpcomingAppointmentItem({                                                                                                              
214 -    required this.appointment,                                                                                                                  
215 -    this.onTap,                                                                                                                                 
216 -  });                                                                                                                                           
217 -                                                                                                                                                
218 -  bool _isToday(DateTime date) {                                                                                                                
219 -    final now = DateTime.now();                                                                                                                 
220 -    return date.year == now.year && date.month == now.month && date.day == now.day;                                                             
221 -  }                                                                                                                                             
222 -                                                                                                                                                
223 -  @override                                                                                                                                     
224 -  Widget build(BuildContext context) {                                                                                                          
225 -    final theme = Theme.of(context);                                                                                                            
226 -    final firestoreService = sl<FirestoreService>();                                                                                            
227 -                                                                                                                                                
228 -    return Padding(                                                                                                                             
229 -      padding: const EdgeInsets.only(bottom: AppConstants.padM),                                                                                
230 -      child: FutureBuilder<UserModel>(                                                                                                          
231 -        future: firestoreService.getUserDetails(appointment.clientId),                                                                          
232 -        builder: (context, snapshot) {                                                                                                          
233 -          final clientName = snapshot.hasData ? snapshot.data!.fullName : 'Loading...';                                                         
234 -          final imageUrl = snapshot.hasData ? snapshot.data?.profilePictureUrl : null;                                                          
235 -                                                                                                                                                
236 -          return Container(                                                                                                                     
237 -            padding: const EdgeInsets.all(AppConstants.padM),                                                                                   
238 -            decoration: BoxDecoration(                                                                                                          
239 -              gradient: LinearGradient(                                                                                                         
240 -                colors: [                                                                                                                       
241 -                  theme.colorScheme.primary.withValues(alpha: 0.05),                                                                            
242 -                  theme.colorScheme.secondary.withValues(alpha: 0.03),                                                                          
243 -                ],                                                                                                                              
244 -                begin: Alignment.topLeft,                                                                                                       
245 -                end: Alignment.bottomRight,                                                                                                     
246 -              ),                                                                                                                                
247 -              borderRadius: BorderRadius.circular(16),                                                                                          
248 -              border: Border.all(                                                                                                               
249 -                color: theme.colorScheme.primary.withValues(alpha: 0.1),                                                                        
250 -              ),                                                                                                                                
251 -              boxShadow: [                                                                                                                      
252 -                BoxShadow(                                                                                                                      
253 -                  color: Colors.black.withValues(alpha: 0.03),                                                                                  
254 -                  blurRadius: 8,                                                                                                                
255 -                  offset: const Offset(0, 2),                                                                                                   
256 -                ),                                                                                                                              
257 -              ],                                                                                                                                
258 -            ),                                                                                                                                  
259 -            child: Row(                                                                                                                         
260 -              children: [                                                                                                                       
261 -                // Avatar with gradient border                                                                                                  
262 -                Container(                                                                                                                      
263 -                  decoration: BoxDecoration(                                                                                                    
264 -                    shape: BoxShape.circle,                                                                                                     
265 -                    gradient: LinearGradient(                                                                                                   
266 -                      colors: [                                                                                                                 
267 -                        theme.colorScheme.primary.withValues(alpha: 0.3),                                                                       
268 -                        theme.colorScheme.secondary.withValues(alpha: 0.3),                                                                     
269 -                      ],                                                                                                                        
270 -                    ),                                                                                                                          
271 -                  ),                                                                                                                            
272 -                  padding: const EdgeInsets.all(2),                                                                                             
273 -                  child: ProfileAvatar(                                                                                                         
274 -                    fullName: clientName,                                                                                                       
275 -                    imageUrl: imageUrl,                                                                                                         
276 -                    radius: 24,                                                                                                                 
277 -                  ),                                                                                                                            
278 -                ),                                                                                                                              
279 -                const SizedBox(width: AppConstants.padM),                                                                                       
280 -                                                                                                                                                
281 -                // Client info                                                                                                                  
282 -                Expanded(                                                                                                                       
283 -                  child: Column(                                                                                                                
284 -                    crossAxisAlignment: CrossAxisAlignment.start,                                                                               
285 -                    children: [                                                                                                                 
286 -                      Text(                                                                                                                     
287 -                        clientName,                                                                                                             
288 -                        style: theme.textTheme.titleMedium?.copyWith(                                                                           
289 -                          fontWeight: FontWeight.bold,                                                                                          
290 -                        ),                                                                                                                      
291 -                        maxLines: 1,                                                                                                            
292 -                        overflow: TextOverflow.ellipsis,                                                                                        
293 -                      ),                                                                                                                        
294 -                      const SizedBox(height: 2),                                                                                                
295 -                      Row(                                                                                                                      
296 -                        children: [                                                                                                             
297 -                          Icon(                                                                                                                 
298 -                            CupertinoIcons.scissors,                                                                                            
299 -                            size: 14,                                                                                                           
300 -                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),                                                          
301 -                          ),                                                                                                                    
302 -                          const SizedBox(width: 4),                                                                                             
303 -                          Text(                                                                                                                 
304 -                            '${appointment.serviceIds.length} service(s)',                                                                      
305 -                            style: theme.textTheme.bodySmall?.copyWith(                                                                         
306 -                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),                                                        
307 -                            ),                                                                                                                  
308 -                          ),                                                                                                                    
309 -                        ],                                                                                                                      
310 -                      ),                                                                                                                        
311 -                    ],                                                                                                                          
312 -                  ),                                                                                                                            
313 -                ),                                                                                                                              
314 -                                                                                                                                                
315 -                // Date + Time badge                                                                                                            
316 -                Column(                                                                                                                         
317 -                  crossAxisAlignment: CrossAxisAlignment.end,                                                                                   
318 -                  mainAxisSize: MainAxisSize.min,                                                                                               
319 -                  children: [                                                                                                                   
320 -                    // Show date if not today                                                                                                   
321 -                    if (!_isToday(appointment.startTime))                                                                                       
322 -                      Padding(                                                                                                                  
323 -                        padding: const EdgeInsets.only(bottom: 4),                                                                              
324 -                        child: Text(                                                                                                            
325 -                          DateFormat('MMM d').format(appointment.startTime),                                                                    
326 -                          style: theme.textTheme.labelSmall?.copyWith(                                                                          
327 -                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),                                                          
328 -                            fontWeight: FontWeight.w600,                                                                                        
329 -                          ),                                                                                                                    
330 -                        ),                                                                                                                      
331 -                      ),                                                                                                                        
332 -                    Container(                                                                                                                  
333 -                      padding: const EdgeInsets.symmetric(                                                                                      
334 -                        horizontal: 12,                                                                                                         
335 -                        vertical: 8,                                                                                                            
336 -                      ),                                                                                                                        
337 -                      decoration: BoxDecoration(                                                                                                
338 -                        gradient: LinearGradient(                                                                                               
339 -                          colors: [                                                                                                             
340 -                            theme.colorScheme.primary,                                                                                          
341 -                            theme.colorScheme.secondary,                                                                                        
342 -                          ],                                                                                                                    
343 -                        ),                                                                                                                      
344 -                        borderRadius: BorderRadius.circular(12),                                                                                
345 -                        boxShadow: [                                                                                                            
346 -                          BoxShadow(                                                                                                            
347 -                            color: theme.colorScheme.primary.withValues(alpha: 0.3),                                                            
348 -                            blurRadius: 6,                                                                                                      
349 -                            offset: const Offset(0, 2),                                                                                         
350 -                          ),                                                                                                                    
351 -                        ],                                                                                                                      
352 -                      ),                                                                                                                        
353 -                      child: Text(                                                                                                              
354 -                        DateFormat.jm().format(appointment.startTime),                                                                          
355 -                        style: theme.textTheme.titleSmall?.copyWith(                                                                            
356 -                          fontWeight: FontWeight.bold,                                                                                          
357 -                          color: Colors.white,                                                                                                  
358 -                        ),                                                                                                                      
359 -                      ),                                                                                                                        
360 -                    ),                                                                                                                          
361 -                  ],                                                                                                                            
362 -                ),                                                                                                                              
363 -              ],                                                                                                                                
364 -            ),                                                                                                                                  
365 -          );                                                                                                                                    
366 -        },                                                                                                                                      
367 -      ),                                                                                                                                        
368 -    );                                                                                                                                          
369 -  }                                                                                                                                             
370 -}                                                                                                                                               
1   No newline at end of file
2 +import 'package:easy_localization/easy_localization.dart';                                                                                      
3 +import 'package:flutter/material.dart';                                                                                                         
4 +import 'package:flutter/cupertino.dart';                                                                                                        
5 +import 'package:intl/intl.dart';                                                                                                                
6 +import 'package:pendeza/app/config/theme/app_constants.dart';                                                                                   
7 +import 'package:pendeza/app/services/firestore_service.dart';                                                                                   
8 +import 'package:pendeza/app/services/service_locator.dart';                                                                                     
9 +import 'package:pendeza/shared/models/appointment_model.dart';                                                                                  
10 +import 'package:pendeza/shared/widgets/profile_avatar.dart';                                                                                    
11 +import '../../../../0_auth/data/models/user_model.dart';                                                                                        
12 +                                                                                                                                                
13 +class UpcomingAppointmentsList extends StatelessWidget {                                                                                        
14 +  final List<AppointmentModel> appointments;                                                                                                    
15 +  final VoidCallback? onAppointmentTap;                                                                                                         
16 +                                                                                                                                                
17 +  const UpcomingAppointmentsList({                                                                                                              
18 +    super.key,                                                                                                                                  
19 +    required this.appointments,                                                                                                                 
20 +    this.onAppointmentTap,                                                                                                                      
21 +  });                                                                                                                                           
22 +                                                                                                                                                
23 +  @override                                                                                                                                     
24 +  Widget build(BuildContext context) {                                                                                                          
25 +    final theme = Theme.of(context);                                                                                                            
26 +                                                                                                                                                
27 +    if (appointments.isEmpty) {                                                                                                                 
28 +      return _buildEmptyState(context);                                                                                                         
29 +    }                                                                                                                                           
30 +                                                                                                                                                
31 +    return Column(                                                                                                                              
32 +      crossAxisAlignment: CrossAxisAlignment.start,                                                                                             
33 +      children: [                                                                                                                               
34 +        // Section header with icon                                                                                                             
35 +        Row(                                                                                                                                    
36 +          children: [                                                                                                                           
37 +            Container(                                                                                                                          
38 +              padding: const EdgeInsets.all(8),                                                                                                 
39 +              decoration: BoxDecoration(                                                                                                        
40 +                gradient: LinearGradient(                                                                                                       
41 +                  colors: [                                                                                                                     
42 +                    theme.colorScheme.primary.withValues(alpha: 0.15),                                                                          
43 +                    theme.colorScheme.secondary.withValues(alpha: 0.15),                                                                        
44 +                  ],                                                                                                                            
45 +                ),                                                                                                                              
46 +                borderRadius: BorderRadius.circular(10),                                                                                        
47 +              ),                                                                                                                                
48 +              child: Icon(                                                                                                                      
49 +                CupertinoIcons.calendar_today,                                                                                                  
50 +                color: theme.colorScheme.primary,                                                                                               
51 +                size: 20,                                                                                                                       
52 +              ),                                                                                                                                
53 +            ),                                                                                                                                  
54 +            const SizedBox(width: 12),                                                                                                          
55 +            Text(                                                                                                                               
56 +              'owner.dashboard.upcoming'.tr(),                                                                                                  
57 +              style: theme.textTheme.titleLarge?.copyWith(                                                                                      
58 +                fontWeight: FontWeight.bold,                                                                                                    
59 +              ),                                                                                                                                
60 +            ),                                                                                                                                  
61 +            const Spacer(),                                                                                                                     
62 +            Container(                                                                                                                          
63 +              padding: const EdgeInsets.symmetric(                                                                                              
64 +                horizontal: 10,                                                                                                                 
65 +                vertical: 4,                                                                                                                    
66 +              ),                                                                                                                                
67 +              decoration: BoxDecoration(                                                                                                        
68 +                gradient: LinearGradient(                                                                                                       
69 +                  colors: [                                                                                                                     
70 +                    theme.colorScheme.primary.withValues(alpha: 0.15),                                                                          
71 +                    theme.colorScheme.secondary.withValues(alpha: 0.15),                                                                        
72 +                  ],                                                                                                                            
73 +                ),                                                                                                                              
74 +                borderRadius: BorderRadius.circular(12),                                                                                        
75 +                border: Border.all(                                                                                                             
76 +                  color: theme.colorScheme.primary.withValues(alpha: 0.3),                                                                      
77 +                ),                                                                                                                              
78 +              ),                                                                                                                                
79 +              child: Text(                                                                                                                      
80 +                '${appointments.length}',                                                                                                       
81 +                style: theme.textTheme.labelMedium?.copyWith(                                                                                   
82 +                  color: theme.colorScheme.primary,                                                                                             
83 +                  fontWeight: FontWeight.bold,                                                                                                  
84 +                ),                                                                                                                              
85 +              ),                                                                                                                                
86 +            ),                                                                                                                                  
87 +          ],                                                                                                                                    
88 +        ),                                                                                                                                      
89 +        const SizedBox(height: AppConstants.padM),                                                                                              
90 +                                                                                                                                                
91 +        // Appointments list with staggered animation                                                                                           
92 +        ...appointments.asMap().entries.map((entry) {                                                                                           
93 +          final index = entry.key;                                                                                                              
94 +          final appointment = entry.value;                                                                                                      
95 +          return TweenAnimationBuilder<double>(                                                                                                 
96 +            tween: Tween(begin: 0.0, end: 1.0),                                                                                                 
97 +            duration: Duration(milliseconds: 300 + (index * 80)),                                                                               
98 +            curve: Curves.easeOutCubic,                                                                                                         
99 +            builder: (context, value, child) {                                                                                                  
100 +              return Opacity(                                                                                                                   
101 +                opacity: value,                                                                                                                 
102 +                child: Transform.translate(                                                                                                     
103 +                  offset: Offset(0, 20 * (1 - value)),                                                                                          
104 +                  child: child,                                                                                                                 
105 +                ),                                                                                                                              
106 +              );                                                                                                                                
107 +            },                                                                                                                                  
108 +            child: _UpcomingAppointmentItem(                                                                                                    
109 +              appointment: appointment,                                                                                                         
110 +              onTap: onAppointmentTap,                                                                                                          
111 +            ),                                                                                                                                  
112 +          );                                                                                                                                    
113 +        }),                                                                                                                                     
114 +      ],                                                                                                                                        
115 +    );                                                                                                                                          
116 +  }                                                                                                                                             
117 +                                                                                                                                                
118 +  Widget _buildEmptyState(BuildContext context) {                                                                                               
119 +    final theme = Theme.of(context);                                                                                                            
120 +                                                                                                                                                
121 +    return Column(                                                                                                                              
122 +      crossAxisAlignment: CrossAxisAlignment.start,                                                                                             
123 +      children: [                                                                                                                               
124 +        // Section header                                                                                                                       
125 +        Row(                                                                                                                                    
126 +          children: [                                                                                                                           
127 +            Container(                                                                                                                          
128 +              padding: const EdgeInsets.all(8),                                                                                                 
129 +              decoration: BoxDecoration(                                                                                                        
130 +                gradient: LinearGradient(                                                                                                       
131 +                  colors: [                                                                                                                     
132 +                    theme.colorScheme.primary.withValues(alpha: 0.15),                                                                          
133 +                    theme.colorScheme.secondary.withValues(alpha: 0.15),                                                                        
134 +                  ],                                                                                                                            
135 +                ),                                                                                                                              
136 +                borderRadius: BorderRadius.circular(10),                                                                                        
137 +              ),                                                                                                                                
138 +              child: Icon(                                                                                                                      
139 +                CupertinoIcons.calendar_today,                                                                                                  
140 +                color: theme.colorScheme.primary,                                                                                               
141 +                size: 20,                                                                                                                       
142 +              ),                                                                                                                                
143 +            ),                                                                                                                                  
144 +            const SizedBox(width: 12),                                                                                                          
145 +            Text(                                                                                                                               
146 +              'owner.dashboard.upcoming'.tr(),                                                                                                  
147 +              style: theme.textTheme.titleLarge?.copyWith(                                                                                      
148 +                fontWeight: FontWeight.bold,                                                                                                    
149 +              ),                                                                                                                                
150 +            ),                                                                                                                                  
151 +          ],                                                                                                                                    
152 +        ),                                                                                                                                      
153 +        const SizedBox(height: AppConstants.padM),                                                                                              
154 +                                                                                                                                                
155 +        // Empty state                                                                                                                          
156 +        Container(                                                                                                                              
157 +          padding: const EdgeInsets.all(AppConstants.padXL),                                                                                    
158 +          decoration: BoxDecoration(                                                                                                            
159 +            gradient: LinearGradient(                                                                                                           
160 +              colors: [                                                                                                                         
161 +                theme.colorScheme.surfaceContainerHighest,                                                                                      
162 +                theme.colorScheme.surface,                                                                                                      
163 +              ],                                                                                                                                
164 +            ),                                                                                                                                  
165 +            borderRadius: BorderRadius.circular(20),                                                                                            
166 +            border: Border.all(                                                                                                                 
167 +              color: theme.colorScheme.outline.withValues(alpha: 0.1),                                                                          
168 +            ),                                                                                                                                  
169 +          ),                                                                                                                                    
170 +          child: Center(                                                                                                                        
171 +            child: Column(                                                                                                                      
172 +              children: [                                                                                                                       
173 +                Container(                                                                                                                      
174 +                  padding: const EdgeInsets.all(16),                                                                                            
175 +                  decoration: BoxDecoration(                                                                                                    
176 +                    color: theme.colorScheme.primary.withValues(alpha: 0.1),                                                                    
177 +                    shape: BoxShape.circle,                                                                                                     
178 +                  ),                                                                                                                            
179 +                  child: Icon(                                                                                                                  
180 +                    CupertinoIcons.checkmark_alt_circle,                                                                                        
181 +                    size: 48,                                                                                                                   
182 +                    color: theme.colorScheme.primary.withValues(alpha: 0.5),                                                                    
183 +                  ),                                                                                                                            
184 +                ),                                                                                                                              
185 +                const SizedBox(height: AppConstants.padM),                                                                                      
186 +                Text(                                                                                                                           
187 +                  'owner.dashboard.no_upcoming'.tr(),                                                                                           
188 +                  style: theme.textTheme.bodyMedium?.copyWith(                                                                                  
189 +                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),                                                                  
190 +                    fontWeight: FontWeight.w500,                                                                                                
191 +                  ),                                                                                                                            
192 +                  textAlign: TextAlign.center,                                                                                                  
193 +                ),                                                                                                                              
194 +                const SizedBox(height: 4),                                                                                                      
195 +                Text(                                                                                                                           
196 +                  'owner.dashboard.no_upcoming_desc'.tr(),                                                                                      
197 +                  style: theme.textTheme.bodySmall?.copyWith(                                                                                   
198 +                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),                                                                  
199 +                  ),                                                                                                                            
200 +                  textAlign: TextAlign.center,                                                                                                  
201 +                ),                                                                                                                              
202 +              ],                                                                                                                                
203 +            ),                                                                                                                                  
204 +          ),                                                                                                                                    
205 +        ),                                                                                                                                      
206 +      ],                                                                                                                                        
207 +    );                                                                                                                                          
208 +  }                                                                                                                                             
209 +}                                                                                                                                               
210 +                                                                                                                                                
211 +class _UpcomingAppointmentItem extends StatelessWidget {                                                                                        
212 +  final AppointmentModel appointment;                                                                                                           
213 +  final VoidCallback? onTap;                                                                                                                    
214 +                                                                                                                                                
215 +  const _UpcomingAppointmentItem({                                                                                                              
216 +    required this.appointment,                                                                                                                  
217 +    this.onTap,                                                                                                                                 
218 +  });                                                                                                                                           
219 +                                                                                                                                                
220 +  bool _isToday(DateTime date) {                                                                                                                
221 +    final now = DateTime.now();                                                                                                                 
222 +    return date.year == now.year && date.month == now.month && date.day == now.day;                                                      
223 +  }                                                                                                                                             
224 +                                                                                                                                                
225 +  @override                                                                                                                                     
226 +  Widget build(BuildContext context) {                                                                                                          
227 +    final theme = Theme.of(context);                                                                                                            
228 +    final firestoreService = sl<FirestoreService>();                                                                                            
229 +                                                                                                                                                
230 +    return Padding(                                                                                                                             
231 +      padding: const EdgeInsets.only(bottom: AppConstants.padM),                                                                                
232 +      child: FutureBuilder<UserModel>(                                                                                                          
233 +        future: firestoreService.getUserDetails(appointment.clientId),                                                                          
234 +        builder: (context, snapshot) {                                                                                                          
235 +          final clientName = snapshot.hasData ? snapshot.data!.fullName : 'common.loading_details'.tr();                                        
236 +          final imageUrl = snapshot.hasData ? snapshot.data?.profilePictureUrl : null;                                                          
237 +                                                                                                                                                
238 +          return Container(                                                                                                                     
239 +            padding: const EdgeInsets.all(AppConstants.padM),                                                                                   
240 +            decoration: BoxDecoration(                                                                                                          
241 +              gradient: LinearGradient(                                                                                                         
242 +                colors: [                                                                                                                       
243 +                  theme.colorScheme.primary.withValues(alpha: 0.05),                                                                            
244 +                  theme.colorScheme.secondary.withValues(alpha: 0.03),                                                                          
245 +                ],                                                                                                                              
246 +                begin: Alignment.topLeft,                                                                                                       
247 +                end: Alignment.bottomRight,                                                                                                     
248 +              ),                                                                                                                                
249 +              borderRadius: BorderRadius.circular(16),                                                                                          
250 +              border: Border.all(                                                                                                               
251 +                color: theme.colorScheme.primary.withValues(alpha: 0.1),                                                                        
252 +              ),                                                                                                                                
253 +              boxShadow: [                                                                                                                      
254 +                BoxShadow(                                                                                                                      
255 +                  color: Colors.black.withValues(alpha: 0.03),                                                                                  
256 +                  blurRadius: 8,                                                                                                                
257 +                  offset: const Offset(0, 2),                                                                                                   
258 +                ),                                                                                                                              
259 +              ],                                                                                                                                
260 +            ),                                                                                                                                  
261 +            child: Row(                                                                                                                         
262 +              children: [                                                                                                                       
263 +                // Avatar with gradient border                                                                                                  
264 +                Container(                                                                                                                      
265 +                  decoration: BoxDecoration(                                                                                                    
266 +                    shape: BoxShape.circle,                                                                                                     
267 +                    gradient: LinearGradient(                                                                                                   
268 +                      colors: [                                                                                                                 
269 +                        theme.colorScheme.primary.withValues(alpha: 0.3),                                                                       
270 +                        theme.colorScheme.secondary.withValues(alpha: 0.3),                                                                     
271 +                      ],                                                                                                                        
272 +                    ),                                                                                                                          
273 +                  ),                                                                                                                            
274 +                  padding: const EdgeInsets.all(2),                                                                                             
275 +                  child: ProfileAvatar(                                                                                                         
276 +                    fullName: clientName,                                                                                                       
277 +                    imageUrl: imageUrl,                                                                                                         
278 +                    radius: 24,                                                                                                                 
279 +                  ),                                                                                                                            
280 +                ),                                                                                                                              
281 +                const SizedBox(width: AppConstants.padM),                                                                                       
282 +                                                                                                                                                
283 +                // Client info                                                                                                                  
284 +                Expanded(                                                                                                                       
285 +                  child: Column(                                                                                                                
286 +                    crossAxisAlignment: CrossAxisAlignment.start,                                                                               
287 +                    children: [                                                                                                                 
288 +                      Text(                                                                                                                     
289 +                        clientName,                                                                                                             
290 +                        style: theme.textTheme.titleMedium?.copyWith(                                                                           
291 +                          fontWeight: FontWeight.bold,                                                                                          
292 +                        ),                                                                                                                      
293 +                        maxLines: 1,                                                                                                            
294 +                        overflow: TextOverflow.ellipsis,                                                                                        
295 +                      ),                                                                                                                        
296 +                      const SizedBox(height: 2),                                                                                                
297 +                      Row(                                                                                                                      
298 +                        children: [                                                                                                             
299 +                          Icon(                                                                                                                 
300 +                            CupertinoIcons.scissors,                                                                                            
301 +                            size: 14,                                                                                                           
302 +                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),                                                          
303 +                          ),                                                                                                                    
304 +                          const SizedBox(width: 4),                                                                                             
305 +                          Text(                                                                                                                 
306 +                            'owner.dashboard.services_count'.tr(args: ['${appointment.serviceIds.length}']),                                    
307 +                            style: theme.textTheme.bodySmall?.copyWith(                                                                         
308 +                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),                                                        
309 +                            ),                                                                                                                  
310 +                          ),                                                                                                                    
311 +                        ],                                                                                                                      
312 +                      ),                                                                                                                        
313 +                    ],                                                                                                                          
314 +                  ),                                                                                                                            
315 +                ),                                                                                                                              
316 +                                                                                                                                                
317 +                // Date + Time badge                                                                                                            
318 +                Column(                                                                                                                         
319 +                  crossAxisAlignment: CrossAxisAlignment.end,                                                                                   
320 +                  mainAxisSize: MainAxisSize.min,                                                                                               
321 +                  children: [                                                                                                                   
322 +                    // Show date if not today                                                                                                   
323 +                    if (!_isToday(appointment.startTime))                                                                                       
324 +                      Padding(                                                                                                                  
325 +                        padding: const EdgeInsets.only(bottom: 4),                                                                              
326 +                        child: Text(                                                                                                            
327 +                          DateFormat('MMM d').format(appointment.startTime),                                                                    
328 +                          style: theme.textTheme.labelSmall?.copyWith(                                                                          
329 +                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),                                                          
330 +                            fontWeight: FontWeight.w600,                                                                                        
331 +                          ),                                                                                                                    
332 +                        ),                                                                                                                      
333 +                      ),                                                                                                                        
334 +                    Container(                                                                                                                  
335 +                      padding: const EdgeInsets.symmetric(                                                                                      
336 +                        horizontal: 12,                                                                                                         
337 +                        vertical: 8,                                                                                                            
338 +                      ),                                                                                                                        
339 +                      decoration: BoxDecoration(                                                                                                
340 +                        gradient: LinearGradient(                                                                                               
341 +                          colors: [                                                                                                             
342 +                            theme.colorScheme.primary,                                                                                          
343 +                            theme.colorScheme.secondary,                                                                                        
344 +                          ],                                                                                                                    
345 +                        ),                                                                                                                      
346 +                        borderRadius: BorderRadius.circular(12),                                                                                
347 +                        boxShadow: [                                                                                                            
348 +                          BoxShadow(                                                                                                            
349 +                            color: theme.colorScheme.primary.withValues(alpha: 0.3),                                                            
350 +                            blurRadius: 6,                                                                                                      
351 +                            offset: const Offset(0, 2),                                                                                         
352 +                          ),                                                                                                                    
353 +                        ],                                                                                                                      
354 +                      ),                                                                                                                        
355 +                      child: Text(                                                                                                              
356 +                        DateFormat.jm().format(appointment.startTime),                                                                          
357 +                        style: theme.textTheme.titleSmall?.copyWith(                                                                            
358 +                          fontWeight: FontWeight.bold,                                                                                          
359 +                          color: Colors.white,                                                                                                  
360 +                        ),                                                                                                                      
361 +                      ),                                                                                                                        
362 +                    ),                                                                                                                          
363 +                  ],                                                                                                                            
364 +                ),                                                                                                                              
365 +              ],                                                                                                                                
366 +            ),                                                                                                                                  
367 +          );                                                                                                                                    
368 +        },                                                                                                                                      
369 +      ),                                                                                                                                        
370 +    );                                                                                                                                          
371 +  }                                                                                                                                             
372 +}                                                                                                                                               
⎿  You've hit your limit · resets Feb 11, 9am (Africa/Dar_es_Salaam)
✻ Churned for 5m 11s                                                
