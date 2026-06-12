# Tennis Score

Нативное iOS-приложение для ведения счёта в большом теннисе.
Два режима: **классический матч** (геймы → сеты → тай-брейки) и
тренировочная игра **«105»** (очки за типы ударов, счёт ведёт тренер).

- SwiftUI · iOS 17+ · без зависимостей · полностью офлайн
- Интерфейс приложения — на английском языке
- Подписка Tennis Score Pro $2.99/мес (StoreKit 2) + пробный день;
  вход через Sign in with Apple или e-mail

## Подписка и вход

- Триал: 24 часа с первого запуска, отсчёт хранится в Keychain
  (App Store не поддерживает нативный однодневный триал — минимум 3 дня).
- Продукт: `com.efremov.tennisscore.pro.monthly` (auto-renewable, $2.99/мес).
- Локальное тестирование покупок: запуск из Xcode — схема подключает
  `TennisScore.storekit` (через `simctl launch` конфиг не применяется,
  пейволл покажет резервную цену).
- Для продажи в проде: аккаунт Apple Developer → App Store Connect →
  создать подписку с тем же Product ID, включить Sign in with Apple
  capability в профиле подписи.
- E-mail-вход — локальная учётная запись без серверной верификации
  (бэкенда нет); Sign in with Apple — нативный.
- Логика счёта — отдельный Swift Package `TennisEngine` (48 unit-тестов)
- 4 темы корта: Уимблдон, Ролан Гаррос, US Open, Мельбурн (light/dark)
- История игр и пресеты правил — SwiftData
- Bundle ID: `com.efremov.tennisscore`

## Сборка

```bash
make setup       # xcodegen (ставится сам) + генерация .xcodeproj
make test        # unit-тесты движка
make typecheck   # быстрая проверка компиляции UI без симулятора
make run         # сборка + установка + запуск в самом новом iPhone-симуляторе
make shots       # скриншоты всех demo-экранов (light + dark) в ./screenshots
make icon        # перегенерировать иконку (нужен Pillow)
```

## Demo-режимы

Приложение принимает launch-аргумент `--demo` для мгновенного открытия
экрана с реалистичными данными (используется `make shots`):

```
--demo home | newmatch | match | tiebreak | 105 | victory | history | settings
```

## Структура

```
TennisEngine/      # движок счёта: чистая логика, без UI
App/
  AppMain/         # @main, SwiftData-контейнер, разбор --demo
  Sources/
    Theme/         # темы корта
    Models/        # SwiftData-модели истории и пресетов
    ViewModels/    # @Observable обёртки движков
    Views/         # экраны и компоненты
    Support/       # haptics, demo-данные, настройки
scripts/           # генерация иконки (Python/Pillow)
```
