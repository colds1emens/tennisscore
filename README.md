# Tennis Score

Нативное iOS-приложение для ведения счёта в большом теннисе.
Два режима: **классический матч** (геймы → сеты → тай-брейки) и
тренировочная игра **«105»** (очки за типы ударов, счёт ведёт тренер).

- SwiftUI · iOS 17+ · без зависимостей · полностью офлайн
- Интерфейс приложения — на английском языке
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
