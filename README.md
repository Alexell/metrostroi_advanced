# Metrostroi Advanced v1.0

**Created by:** Alexell & Agent Smith

**Website:** https://alexell.ru/
 
![Metrostroi Advanced v1](http://metrostroi.alexell.ru/images/metrostroi_advanced.jpg)

**Описание:**

Расширение для Метростроя, добавляющее много полезных возможностей для серверов и игроков.

**Изменения стандартных возможностей:**
* Изменена команда `!station`, теперь все выводы на русском языке
* Изменена команда `!trains`, теперь выводит игрока, его состав, кол-во вагонов и номер маршрута

**Новые возможности:**
* Добавлена команда `!stations`, которая выводит список станций и других объектов для телепортации на карте
* Добавлена команда `!expass` - высаживает пассажиров из состава, сделано для удобства, чтобы не вводить консольную команду
* При подключении клиентов к серверу, у них выполняются специальные консольные команды для оптимизации Garry's Mod
* Добавлена возможность сделать глобальную задержку между спавнами составов (защита от частого переспавна)
* Добавлен вывод в чат сообщения о спавне состава игроком (игрок, состав, кол-во вагонов и местоположение)
* Добавлена возможность сделать ограничение на спавн составов по рангам с помощью прав ULX
* Добавлены права ULX на +1, +2 и +3 доступных для спавна вагонов, можно выдать определенным рангам
* Добавлена возможность запретить спавнить короткие составы
* Добавлена возможность запретить спавны в местоположении "перегон". **Внимание:** если вы не переписали StationConfiguration для карт, я рекомендую не убирать право **metrostroi_anyplace_spawn** у групп, во избежание проблем со спавном.
* Добавлена опциональная возможность автоматически устанавливать номера маршрутов на составы игроков
* Добавлена команда !traintp (если в составе есть запущенная кабина, то игрока сажает в кабину, если нет - то телепортирует к составу)
* Добавлена команда !signaltp (телепортирует к светофору по его названию)
* Добавлен фикс деповских пневмомагистралей на карте Imagine Line, благодаря чему у вас больше не будут возникать коллизии
* Добавлена команда !udc (восстанавливает исходные положения удочек в депо)

**Необходимые аддоны:**

* Metrostroi
* ULX
* ULib

**Установка на сервер:**
* Добавить в коллекцию сервера: [Metrostroi Advanced v1](https://steamcommunity.com/sharedfiles/filedetails/?id=1838480881)

## Информация по настройке и использованию аддона

Все измененные и новые команды находятся в категории "Metrostroi Advanced". В разделе Permissions, права на доступ к командам находятся в категории "Cmds - Metrostroi Advanced", а остальные права в категории "Metrostroi Advanced".

### Первичная настройка аддона

**1.** Открываете `server.cfg` вашего сервера.

**2.** Добавляете следующие конвары:
* **metrostroi_advanced_spawninterval 0** //задержка между спавнами в секундах, по умолчанию отключена (0).
* **metrostroi_advanced_trainsrestrict 0** //вкл(1)/выкл(0) ограничение на спавн составов по правам ULX, по умолчанию выключено.
* **metrostroi_advanced_spawnmessage 1** //вкл(1)/выкл(0) сообщение в чат о спавне составов игроками, по умолчанию включено.
* **metrostroi_advanced_maxwagons 4** //разрешенное кол-во вагонов на игрока, по умолчанию 4.
* **metrostroi_advanced_routenums 1** //вкл(1)/выкл(0) автоматическая установка номеров маршрутов на составы.

**3.** Изменяете стандартную квару так: **metrostroi_maxwagons 6**

**4.** Запускаете сервер и расставляете права по нужным группам, не забывая про наследование, если оно у вас настроено.

### О лимитах на вагоны
Мы устанавливаем **metrostroi_maxwagons 6** на максимальное число вагонов, чтобы использовать собственные ограничения аддона.

Для игроков будет доступно для спавна столько вагонов, сколько указано в **metrostroi_advanced_maxwagons**. Для групп, которым вы добавите права **add_1wagons**, **add_2wagons** и **add_3wagons**, количество вагонов для спавна будет увеличено на соответствующее значение.

**Обратите внимание:** права на доп. вагоны **не суммируются**! Если из-за наследования получится так, что например машинистам 1 класса будет доступны сразу 2 права - на +1 вагон и на +2 вагона, у него **не будет возможности заспавнить +3 вагона** от значения **metrostroi_advanced_maxwagons**. Он сможет заспавнить только **+2** вагона, потому что действует всегда только одно право - которое больше.

Будьте внимательны при настройке лимитов на вагоны. Если у вас на сервере всем доступно 4 вагона (**metrostroi_advanced_maxwagons 4**), то вы сможете выдавать права группам только на +1 и +2 вагона. Если выдатите и на +3, то группе станет доступно **7 вагонов**, но игроки не смогут их заспавнить, потому что стандартная квара **metrostroi_maxwagons** установлена в **6**.
