#!/bin/bash
# Lancer depuis la racine de ton projet Flutter
# bash setup_structure.sh

echo "📁 Création de la structure MediRemind..."

# Assets
mkdir -p assets/images
mkdir -p assets/icons

# Core
mkdir -p lib/core/constants
mkdir -p lib/core/theme
mkdir -p lib/core/utils

# Data
mkdir -p lib/data/models
mkdir -p lib/data/database
mkdir -p lib/data/repositories

# Services
mkdir -p lib/services

# UI - Screens
mkdir -p lib/ui/screens/splash
mkdir -p lib/ui/screens/auth
mkdir -p lib/ui/screens/home
mkdir -p lib/ui/screens/medicaments
mkdir -p lib/ui/screens/journal
mkdir -p lib/ui/screens/profil

# UI - Widgets
mkdir -p lib/ui/widgets

# Création des fichiers de base vides
touch lib/core/constants/app_colors.dart
touch lib/core/constants/app_strings.dart
touch lib/core/constants/app_routes.dart
touch lib/core/theme/app_theme.dart
touch lib/core/utils/date_helper.dart

touch lib/data/models/medicament.dart
touch lib/data/models/prise.dart
touch lib/data/models/utilisateur.dart
touch lib/data/database/database_helper.dart
touch lib/data/database/medicament_dao.dart
touch lib/data/database/prise_dao.dart
touch lib/data/database/utilisateur_dao.dart
touch lib/data/repositories/medicament_repository.dart
touch lib/data/repositories/prise_repository.dart

touch lib/services/notification_service.dart
touch lib/services/stock_service.dart
touch lib/services/observance_service.dart
touch lib/services/auth_service.dart

touch lib/ui/screens/splash/splash_screen.dart
touch lib/ui/screens/auth/login_screen.dart
touch lib/ui/screens/auth/register_screen.dart
touch lib/ui/screens/auth/forgot_password_screen.dart
touch lib/ui/screens/home/home_screen.dart
touch lib/ui/screens/medicaments/liste_medicaments_screen.dart
touch lib/ui/screens/medicaments/form_medicament_screen.dart
touch lib/ui/screens/journal/journal_screen.dart
touch lib/ui/screens/profil/profil_screen.dart

touch lib/ui/widgets/medicament_card.dart
touch lib/ui/widgets/prise_tile.dart
touch lib/ui/widgets/stock_indicator.dart
touch lib/ui/widgets/observance_badge.dart

echo "✅ Structure créée avec succès !"
echo ""
echo "📦 Lance maintenant : flutter pub get"
