# xcode-github-app

## To Do
```
* [x] Update bot status detail message strings.
* [x] Make log window.
* [x] Add icon to status window.
* [x] Add icon to status line.
* [x] Make preferences dialog: 'Observe' only mode, refresh interval.
* [x] Change to use NSPopover from APArrowPanel
* [x] Make "Add Server" flow.
* [x] Make "Add GitHub Token" flow.
* [x] Add tests.
* [ ] Change status from table to tree. 
* [ ] Clean up code. 
* [ ] Add help.
```
 
## Menus
* New Server
* New Bot
* View Status
* View Log Window
* View Servers
* Help

## Windows

### Status - Main Window
Status view: a table with columns
* Test status: Blue: Building, Yellow: Warnings, Red: Error, Green: Success, Grey: Unknown
* Xcode Server Host
* Pull Request Name
* Status Summary
* Button: Start / Stop Button
* Button: Download logs

- or - 

Tree:
| Server | Project |  


### Settings Window
* Add server
* Add GitHub Token
* Dry run, show debug messages, refresh time
 
### Log Window
Shows the xcode-github log messages.
