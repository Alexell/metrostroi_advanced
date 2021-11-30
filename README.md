# Metrostroi Advanced

**Версия: 2.0**

**Разработчики:** [Alexell](https://steamcommunity.com/profiles/76561198210303223) и [Agent Smith](https://steamcommunity.com/profiles/76561197990364979)
 
![Metrostroi Advanced v1](http://mss.community/images/addons/metrostroi_advanced.jpg)

**Описание:**

Расширение для Метростроя, добавляющее много полезных возможностей для серверов и игроков.

**Изменения стандартных возможностей:**
* Изменена команда `!station`, теперь все выводы локализованы
* Изменена команда `!trains`, теперь выводит игрока, его состав, кол-во вагонов и номер маршрута
* Заменена команда !binds для запуска меню биндов Метростроя, теперь отрабатывает нормально

**Новые возможности:**
* Добавлена команда !swn для установки собственного бортового номера вагона
* Добавлена команда !entitytp для телепорта к любой энтити по ее ID
* Реализована система "Автоинформатор", которая по прибытии состава на станцию, автоматически проигрывает запись информатора на составах с системой АСНП (включая 81-760 "Ока")
* В меню [Q]->Утилиты->Metrostroi Advanced добавлена панель "Клиент" с опциями: "Использовать рекоменд. оптимизацию клиента", "Использовать автоинформатор", "Автоматически выдавать номер маршрута"
* В меню [Q]->Утилиты->Metrostroi Advanced добавлена панель "Админ" с возможностью управления почти всеми параметрами этого аддона, а также несколькоми серверными параметрами Метростроя: "Вкл. необходимость наличия КР", "Напряжение на КР", "Ограничение тока подстанции" и они реально работают =)
* Добавлена команда `!stations`, которая выводит список станций и других объектов для телепортации на карте
* Добавлена команда `!expass` - высаживает пассажиров из состава, сделано для удобства, чтобы не вводить консольную команду
* Добавлена опциональная возможность выполнять команды для оптимизации клиентов Garry's Mod
* Добавлена возможность сделать глобальную задержку между спавнами составов (защита от частого переспавна)
* Добавлен вывод в чат сообщения о спавне состава игроком (игрок, состав, кол-во вагонов и местоположение)
* Добавлена возможность сделать ограничение на спавн составов по рангам с помощью прав ULX
* Добавлены права ULX на +1, +2 и +3 доступных для спавна вагонов, можно выдать определенным рангам
* Добавлена возможность запретить спавнить короткие составы
* Добавлена возможность запретить спавны в местоположении "перегон". **Внимание:** если вы не переписали StationConfiguration для карт, я рекомендую не убирать право **metrostroi_anyplace_spawn** у групп, во избежание проблем со спавном.
* Добавлена опциональная возможность автоматически устанавливать номера маршрутов на составы игроков
* Добавлена команда `!traintp` (если в составе есть запущенная кабина, то игрока сажает в кабину, если нет - то телепортирует к составу)
* Добавлена команда `!signaltp` (телепортирует к светофору по его названию)
* Добавлен фикс деповских пневмомагистралей на карте Imagine Line, благодаря чему у вас больше не будут возникать коллизии
* Добавлена команда `!udc` (восстанавливает исходные положения удочек в депо)
* Удобный подсчет доступных для спавна вагонов, которые теперь отображаются и в **!trains**
* Возможность автоматически разрешать спавн 4-х вагонов при небольшом количестве вагонов на сервере
* Добавлена команда `!enter` чтобы посадить любого игрока в кресло машиниста (для админов и инструкторов)
* Добавлена команда `!expel` чтобы высадить любого игрока с любого места в составе (для админов и инструкторов)
* Добавлена команда `!ch` для простой смены кабины
* Добавлена команда `!sch` для умной смены кабины
* Добавлена команда `!trainstart` для запуска кабины
* Добавлена команда `!trainstop` для выключения кабины
* Добавлена возможность автоматически кикать AFK игроков
* Добавлена возможность установки часового пояса для времени сервера
* Добавлена возможность запретить спавн на станциях (редактируемый список слов для игнора находится в файле data/metrostroi_advanced/stations_ignore.txt)
* Добавлена возможность ограничить кол-во вагонов на состав, в зависимости от карты (файл data/metrostroi_advanced/map_wagons.txt)

**Необходимые аддоны:**

* Metrostroi
* ULX
* ULib

**Установка на сервер:**
* Добавить в коллекцию сервера: [Metrostroi Advanced](https://steamcommunity.com/sharedfiles/filedetails/?id=1838480881)

## Информация по настройке и использованию аддона

Все измененные и новые команды находятся в категории "Metrostroi Advanced". В разделе Permissions, права на доступ к командам находятся в категории "Cmds - Metrostroi Advanced", а остальные права в категории "Metrostroi Advanced".

### Первичная настройка аддона

**1.** Открываете `server.cfg` вашего сервера.

**2.** Добавляете следующие конвары:
* **metrostroi_advanced_lang "ru"** //локализация серверной части аддона (выводы в чат), доступные языки "ru" и "en", по умолчанию "ru".
* **metrostroi_advanced_spawninterval 0** //задержка между спавнами в секундах, по умолчанию отключена (0).
* **metrostroi_advanced_trainsrestrict 0** //вкл(1)/выкл(0) ограничение на спавн составов по правам ULX, по умолчанию выключено.
* **metrostroi_advanced_spawnmessage 1** //вкл(1)/выкл(0) сообщение в чат о спавне составов игроками, по умолчанию включено.
* **metrostroi_advanced_minwagons 2** //минимально вагонов в составе, по умолчанию 2.
* **metrostroi_advanced_maxwagons 4** //разрешенное кол-во вагонов на игрока, по умолчанию 4.
* **metrostroi_advanced_autowags 0** //вкл(1)/выкл(0) автоматическое разрешение на 4 вагона при малом кол-ве вагонов на сервере
* **metrostroi_advanced_afktime 0** //время бездействия в минутах, после которого игрок будет кикнут, по умолчанию выключено (0).

**3.** Изменяете стандартную квару так: **metrostroi_maxwagons 6**

**4.** Запускаете сервер и расставляете права по нужным группам, не забывая про наследование, если оно у вас настроено.

### О местоположениях
Для определения местоположения спавна используются точки телепорта из Metrostroi.StationConfigurations.

Чтобы местоположение спавна определялось корректно, рекомендуем расставить точки телепорта по центру станций. Что же касается депо, тупиков и оборотов, там потребуется самостоятельно проверять, как определяется местоположение и передвигать/создавать точки телепорта на свое усмотрение.

### О лимитах на вагоны
Мы устанавливаем **metrostroi_maxwagons 6** на максимальное число вагонов, чтобы использовать собственные ограничения аддона.
Аддон теперь учитывает макс. кол-во вагонов на сервере, которое рассчитывается как **(metrostroi_maxtrains * metrostroi_advanced_maxwagons)**.

При **metrostroi_advanced_autowags 1** всем игрокам будет доступно 4 вагона для спавна до тех пор, пока на сервере меньше 8 вагонов, далее для спавна будет доступно уже только 3 вагона.
При **metrostroi_advanced_autowags 0** всем игрокам  будет доступно для спавна столько вагонов, сколько указано в **metrostroi_advanced_maxwagons**.

В обоих случаях, для групп, которым вы добавите права **add_1wagons**, **add_2wagons** и **add_3wagons**, количество вагонов для спавна будет увеличено на соответствующее значение.

**Обратите внимание:** права на доп. вагоны **не суммируются**! Если из-за наследования получится так, что например машинистам 1 класса будет доступны сразу 2 права - на +1 вагон и на +2 вагона, у него **не будет возможности заспавнить +3 вагона** от значения **metrostroi_advanced_maxwagons**. Он сможет заспавнить только **+2** вагона, потому что действует всегда только одно право - которое больше.

Будьте внимательны при настройке лимитов на вагоны. Вам нужно настроить параметры так, чтобы игроки не могли заспавнить больше вагонов, чем выдерживает ваш сервер. Например, если вы хотите установить серверу максимально 24 вагона, то необходимо указать следующие значения:
```
metrostroi_maxtrains 8
metrostroi_advanced_maxwagons 3
```
Если при спавне окажется что игроку доступно больше вагонов, чем указано в **metrostroi_maxwagons** (например из-за права на +3 вагона при **metrostroi_advanced_maxwagons 4**, то игроку все равно будет доступно только указанное в **metrostroi_maxwagons** количество вагонов, как абсолютный максимум.
