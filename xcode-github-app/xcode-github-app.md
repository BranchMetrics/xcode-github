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
* [x] Fix security.
* [x] On bots, if last integration# != current# then update the status on GitHub.
* [x] Clean up code.
* [x] Refresh Sec -> Min 
* [ ] Rename build products: XcodeGitHub.framework, Xcode-GitHub.app, xcode-github (cli tool), Tests
* [ ] Fix tests, test name, and bindings.
* [ ] Add 'New' menu items: Add new server, new Xcode bot.
* [ ] Add 'About...' panel.
* [ ] Add help.
```
 
 ## Help
 * About
   - Problems it solves.
   - What it does.
   - How to do it.

 * Setup & Use
   1. Create an Xcode bot on the Xcode server as a template: The PR bots will be modelled after this bot exactly.
   2. In the Xcode-GitHub app, add the Xcode server as a new server.
   3. The Xcode bot you want to create as a server will appear in the status list.
   4. Select the bot and select 'Use as Template'. A checkmark will appear next to the bot.
   5. When a new PRs on the repo of the template bot  will now automatically be created and run.
   
 * Credits
   - Branch Metrics for the time and resources to cretae this tool.
   - Design & Programming: Edward Smith.
   
* What I Learned
  - Updated my Mac programming skills.
     * It's more like iOS programming now, with formal view controllers and table view delegates.
  - I wanted to explore different ways of create static and libraries, and unit test interaction. 

### References
* [Help Programming Guide](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/ProvidingUserAssitAppleHelp/user_help_intro/user_assistance_intro.html#//apple_ref/doc/uid/TP30000903-CH204-CHDIDJFE)

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
