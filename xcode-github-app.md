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
* [-] Change status from table to tree.
* [x] Add smart sort - by repository then by branchOrPR
* [x] Create new bot flow.
* [ ] Fix security.
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

### Status View - Main Window

#### Table with Columns

* Status 
  - Icon: Test status: Blue: Building, Yellow: Warnings, Red: Error, Green: Success, Grey: Unknown
  - Status Summary
* Xcode Server Host
* Repository
* Branch or Pull Request Name
* Maybe: Button: Start / Stop Button
* Maybe: Button: Download logs

- or - 

#### Tree with Columns

| Server | Repo | PRs | Status |

Server
   +------ Repo
                 +----- PR -- Status

### Settings Window
* Add server
* Add GitHub Token
* Dry run, show debug messages, refresh time
 
### Log Window
Shows the xcode-github log messages.
