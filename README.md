# AnyaLink 🏠🔗

**AnyaLink** is a comprehensive IoT management platform that enables users to control and monitor IoT devices remotely through a Flutter mobile application, with a Supabase backend for authentication and database management, and Node-RED for automation and device communication via MQTT.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
[![Node-RED](https://img.shields.io/badge/Node--RED-Automation-red.svg)](https://nodered.org/)

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
- [Database Schema](#database-schema)
- [User Roles & Permissions](#user-roles--permissions)
- [Usage Guide](#usage-guide)
- [Node-RED Integration](#node-red-integration)
- [Security](#security)

## ✨ Features

### User Management & Authentication
- **Secure Authentication** via Supabase Auth
- **Role-Based Access Control (RBAC)**: Admin and Guest roles
- **User Profiles** with email syncing
- **Device Request System** for Guests to request device access

### Device Management
- **Real-time Device Control** (ON/OFF toggles, message sending)
- **Multiple Device Types**: Lights, Screens (LCD), Dispensers, Cameras
- **Device Assignment System** for admins to assign devices to users
- **Concurrent Access Prevention** with device locking mechanism

### Automation & Routines
- **User-Defined Routines**: Create automated actions (e.g., toggle device every X seconds)
- **Routine Management**: Enable/disable, delete routines
- **Node-RED Integration** for executing routines

### Activity Monitoring
- **Activity Logs**: Track all device actions (who, what, when)
- **Analysis Dashboard** (Admin-only) to view activity history

### UI/UX
- **Dark Mode Support** with persistent preferences
- **Responsive Design** optimized for mobile
- **Material 3 Design** with custom theming
- **Real-time Updates** via Supabase Realtime (optional polling fallback)
- **Weather Widget** with geolocation integration

## 🏗️ Architecture

```
┌─────────────────┐
│  Flutter App    │
│  (Mobile UI)    │
└────────┬────────┘
         │
         ├─────────────────────────┐
         │                         │
    ┌────▼─────┐            ┌─────▼──────┐
    │ Supabase │            │  Node-RED  │
    │ Backend  │◄───────────┤ Automation │
    └────┬─────┘            └─────┬──────┘
         │                         │
         │                         │
    ┌────▼─────────────────────────▼────┐
    │         MQTT Broker                │
    └────────────────┬──────────────────┘
                     │
              ┌──────▼──────┐
              │ IoT Devices │
              │ (ESP32, etc)│
              └─────────────┘
```

## 🛠️ Tech Stack

### Frontend
- **Flutter** (Dart) - Mobile framework
- **Riverpod** - State management
- **Supabase Flutter SDK** - Backend integration
- **Material 3** - UI design

### Backend
- **Supabase** - PostgreSQL, Auth, RLS, Realtime
- **Node-RED** - Automation engine
- **MQTT** - IoT communication

### IoT
- **ESP32** - Microcontroller
- **MQTT Client** - Device communication

## 🚀 Setup Instructions

### 1. Clone & Install

```bash
git clone https://github.com/mateosalas28066/anyalink.git
cd anyalink
flutter pub get
```

### 2. Configure Supabase

1. Create project at [supabase.com](https://supabase.com)
2. Run SQL scripts (in order):
   - `supabase_schema.sql`
   - `fix_recursion.sql`
   - `fix_email_schema.sql`
   - `routines_schema.sql`
   - `activity_logs_schema.sql`
3. Update `lib/core/env.dart` with your credentials

### 3. Set Up Node-RED

```bash
npm install -g node-red
node-red
```

Import `nodered_routines_http_flow.json` and configure MQTT broker.

### 4. Run App

```bash
flutter run
```

## 🗄️ Database Schema

### Key Tables
- **profiles**: User info and roles
- **devices**: IoT device registry
- **user_devices**: Device assignments
- **device_requests**: Access requests
- **routines**: Automated actions
- **activity_logs**: Action history

## 👥 User Roles

### Admin
✅ Manage all devices
✅ Approve requests
✅ View analytics
✅ Full control

### Guest
✅ Control assigned devices
✅ Create routines
✅ Request access
❌ No analytics access

## 📱 Usage

### Guests
1. Sign in
2. Request device access (FAB button)
3. Wait for admin approval
4. Control devices & create routines

### Admins
1. Sign in
2. Go to Admin dashboard
3. Approve requests & assign devices
4. Monitor activity in Analysis tab

## 🔒 Security

- **RLS enabled** on all tables
- **Service Key** for Node-RED only
- **Anon Key** for Flutter app
- Activity logging for audit trails

## 🎨 Features Highlights

- 🌓 **Dark Mode** with persistent settings
- 📊 **Real-time Activity Logs** (Admin)
- ⏰ **Automated Routines** (1h auto-expire)
- 🔐 **Secure RBAC** with Supabase RLS
- 📱 **Material 3** modern UI

## 👨‍💻 Author

**Mateo Salas**
- GitHub: [@mateosalas28066](https://github.com/mateosalas28066)

---

**Built with Flutter, Supabase & Node-RED** ❤️
