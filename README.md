
## Project Y Roleplay Gamemode

This repository contains a modular Roleplay gamemode for Multi Theft Auto: San Andreas. It uses a MySQL database and a custom GUI framework. Each module is implemented as a standalone MTA resource under the `resources` directory.

### Modules
- **pyrp_core** – Initializes the database connection and provides player data loading/saving events.
 - **health_system** – Tracks injuries, bleeding and unconscious state with commands for diagnosis, treatment and ambulance calls.
- **job_system** – Employment office that lets players apply for jobs if they meet license and level requirements. Tracks active job, XP and saves a history of previous positions.
- **faction_system** – Handles faction creation and invitations. The resource
  creates default factions *VLADA*, *EMS*, *PD* and *HASIC* on start and exposes
  their names for other modules.
- **inventory** – Weight-based inventory stored in MySQL.
- **gps** – Example GPS waypoint system.
- **city_web** – In-game city portal with announcements, fines and election voting.
- **web_portal** – PHP website sharing the game database. Players opening it from the game are logged in automatically via a one-time token.
- **vip_system** – Account VIP tiers with daily bonuses and purchase commands.
- **skill_system** – Character skill progression with XP and level tracking.
- **property_system** – Manage real estate ownership, rentals, locks and taxes.
- **needs_system** – Simulates hunger, thirst and fatigue with periodic decay and simple consume commands. VIP players lose needs more slowly.
- **leaderboard_system** – Generates dynamic leaderboards for job XP, wealth, factions and wanted levels.
- **account_system** – Persists accounts in MySQL with hashed passwords, optional 2FA and a trust score system. Includes a polished login panel and multi-character support.
- **admin_system** – Administration panel with kick/ban/mute commands, teleport tools, reports and logging.
- **bank_system** – Handles personal and company bank accounts, transactions, taxes and fines.
- **vehicle_system** – Manages vehicle ownership with locking, STK and insurance records.
- **phone_system** – Provides phone numbers, SMS and call commands with contact storage.
- **market_system** – Player marketplace for trading inventory items.
- **education_system** – Courses and tests that grant certificates like driving or pilot licenses.
- **politics_system** – Handles mayor elections with candidate registration, voting commands and mayor announcements.
- **police_system** – Provides warrant issuing, arresting, jailing and criminal records.
- **event_system** – Allows administrators and factions to schedule RP events, register participants and list upcoming activities.
- **dynamic_events** – Random RP incidents dispatched to EMS, PD or fire.

These modules are minimal examples meant for further expansion and debugging.

### Owl Gaming Inspired Features
- **character_system** – Multi-character support similar to Owl Gaming's setup.
- **property_system** – Real estate system allowing players to buy, rent and lock properties with sharable keys. Includes taxes, selling back to the city and tenant eviction commands.
- **bank_system** – Advanced banking with transfers, tax records and fines.

### Base Gameplay Features
- **account_system** – Secure account storage with hashed passwords, trust score, optional two-factor authentication and a multi-character selector.
- **admin_system** – In-game panel for player management, admin chat and a report queue.
- **health_system** – Provides injury states, medical treatment options and ambulance calls.
- **inventory** – Weight-based inventory with give/drop commands.
- **vehicle_system** – Vehicle ownership with locking, fuel and STK information.
- **police_system** – Warrants, arrests and jail with criminal records.
- **phone_system** – Basic phone support with calling, SMS and contacts.
- **market_system** – Player marketplace for trading inventory items.
- **education_system** – Provides driving and pilot tests with certificates.
- **web_portal** – External PHP site that shares the same MySQL database as the in-game city web and accepts one-time tokens for automatic login from the game.
- **leaderboard_system** – Dynamic leaderboards for top jobs, richest players and wanted criminals.
- **event_system** – Supports planning RP events, participant registration and calendar listings.
- **dynamic_events** – Random RP incidents dispatched to EMS, PD or fire.

These new modules expand the skeleton to more closely resemble an Owl Gaming style server.

