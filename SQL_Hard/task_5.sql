-- Задача 2*: Комплексный анализ эффективности производства

-- Разработайте запрос, который анализирует эффективность каждой мастерской, учитывая:
-- - Производительность каждого ремесленника (соотношение созданных продуктов к затраченному времени)
-- - Эффективность использования ресурсов (соотношение потребляемых ресурсов к производимым товарам)
-- - Качество производимых товаров (средневзвешенное по ценности)
-- - Время простоя мастерской
-- - Влияние навыков ремесленников на качество товаров

-- WORKSHOPS workshop_id, name, type;                                    -- Мастерская
-- WORKSHOP_CRAFTSDWARVES workshop_id, dwarf_id, assignment_date;        -- Рабочие мастерской
-- WORKSHOP_MATERIALS workshop_id, material_id, is_input, quantity;      -- Материалы
-- WORKSHOP_PRODUCTS workshop_id, product_id, production_date, quantity; -- Товары
-- PRODUCTS product_id, material_id, quality, value, workshop_id, created_by
-- PROJECTS project_id, workshop_id                                      -- Проекты
-- PROJECT_WORKERS project_id, dwarf_id                                  -- Работники проектов
-- PROJECT_MATERIALS project_id, material_id, quantity_required, quantity_available -- Материалы проектов
-- PROJECT_DEPENDENCIES project_id, dependent_project_id                 -- Зависимости проектов
-- PROJECT_ZONES project_id, zone_id                                     -- Зоны проектов
-- ORDERS order_id, project_id                                           -- Приказы

-- Навыки гномов, необходимые для работы в мастерской. Т.к. в таблицах не указан конкретный навык для 
--                мастерской/проекта/задачи, есть следующие варианты:
--                1. Есть только один навык, например, 'craft'.
--                2. Есть несколько разных навыков, в зависимости от типа мастерской 'craft', 'tailor', 'art'...
--                3. WORKSHOP_CRAFTSDWARVES.role обозначает профессию, на которую назначен гном. Т.е. по сути, навык.
--                Для запроса использован второй вариант.
--
-- Проекты в мастерских. Судя по БД, в PROJECTS хранится информация обо всех проектах, для выполнения некоторых требуется мастерская.
--                У проектов есть собственные подчиненные таблицы, которые перечакаются с похожими таблицами для мастерской: 
--                PROJECT_MATERIALS, PROJECT_WORKERS, ORDERS.
--                Будем считать, что 
--                1. Требуемые материалы для проекта PROJECT_MATERIALS должны быть на складе мастерской WORKSHOP_MATERIALS
--                2. Назначенные на проект гномы PROJECT_WORKERS должны быть из числа работников мастерской WORKSHOP_CRAFTSDWARVES.
-- Процент загрузки мастерской. Отношение текущей скорости производства товаров к максимально возможной. Простои могут возникать из-за
--                недостатка рабочих, нехватки материалов или отсуствия назначенных проектов.
--                Расчет текущей производительности мастерской берем как среднее колчиество произведенных товаров за отрезок времени (daily).
--                Расчет максимальной производительности:
--                1. Константное значение производительности (н-р. 4 товара в день).
--                2. В зависимости от кратчайшего срока реализации проекта. 
--                3*. С учетом навыка рабочего: рабочие с высоким уровнем навыка работают быстрее.(Можно применить к константной производительности)
--                Используем 1 + 3: для мастерской задана константная максимальная производительнось для одного гнома с навыком '1' за один день.
--                Каждый следующий уровень навыка повышает скорость на 5% (обычный процент: 5, 10, 15...)
--                Общая производительность мастерской рассчитывается как сумма производительностей назначенных гномов.
-- Корреляция качества товара и навыка гнома-создателя. По каждому PRODUCT берем создателя (created_by -> dwarf_id -> skill_level) и качество товара.
--                Ищем коэффицент корреляции: (count(product) * SUM(skill_level*quality)) - SUM(skill_level)*SUM(quality))/SQRT(count(product*SUM(skill_level)^2 - product*SUM(quality)^2)
--                Можно сделать отдельный CTE, рассчитав все промежуточные значение и обработав пустые строки.
--                Для краткости предположим, что у нас СУБД (Oracle/Postgres) уже поддерживает нужную формулу: corr(skill_level, quality)


-- total_quantity_produced              -- Общее количество произведенных товаров
-- -- SUM(WORKSHOP_PRODUCTS.quantity) GROUP BY (WORKSHOP_PRODUCTS.workshop_id)
-- total_production_value               -- Общая ценность произведенных товаров
-- -- SUM(PRODUCT.value) JOIN WORKSHOP_PRODUCT GROUP BY (WORKSHOP_PRODUCTS.workshop_id)
-- daily_production_rate                -- Средний показатель ежедневной продуктивности
-- -- AVG( COUNT(WORKSHOP_PRODUCTS) GROUP BY (WORKSHOP_PRODUCTS.workshop_id, WORKSHOP_PRODUCTS.production_date) )
-- value_per_material_unit              -- Ценность на единицу потраченного материала
-- -- SUM(WORKSHOP_MATERIALS.quantity) GROUP BY (WORKSHOP_MATERIALS.workshop_id) / total_production_value
-- workshop_utilization_percent         -- Процент загрузки мастерской
-- -- daily_production_rate/( SUM( 1 + WORKSHOP_CRAFTDWARVES.skill_level*5/100 )*2)
-- material_conversion_ratio            -- Коэффициент переработки материала
-- -- SUM(NOT WORKSHOP_MATERIALS.is_input) / SUM(WORKSHOP_MATERIALS.is_input) GROUP BY workshop_id
-- average_craftsdwarf_skill            -- Средний уровень навыке назначенных гномов
-- -- SUM ( SELECT dwarf_skills.level FROM dwarf_skills WHERE dwarf_skills.dwarf_if IN (...)) / COUNT(WORKSHOP_CRAFTDWARVES.dwarf_id) GROUP BY workshop_id
-- skill_quality_correlation            -- Зависимость качества товара от навыка гнома
-- -- SELECT corr(skill_level, quality) FROM PRODUCTS JOIN WORKSHOP_PRODUCTS JOIN WORKSHOP_CRAFTDWARVES JOIN DWARF_SKILLS
-- craftsdwarf_ids                      -- Список назначенных гномов
-- -- SELECT dwarf_id FROM WORKSHOP_CRAFTDWARVES WHERE workshop_id = ? 
-- product_ids                          -- Список произведенных товаров
-- -- SELECT DISTINCT product_id FROM WORKSHOP_PRODUCTS WHERE workshop_id = ?
-- material_ids                         -- Список используемых материалов
-- -- SELECT DISTINCT material_id FROM WORKSHOP_MATERIALS WHERE workshop_id = ?
-- project_ids                          -- Список реализуемых проектов
-- -- SELECT project_id from PROJECTS WHERE workshop_id = ?


WITH 
workshop_dwarves_skills AS(
  SELECT wc.dwarf_id
       , (CASE WHEN skill.skill_id IS NOT NULL THEN ds.level ELSE 0) skill_level
    FROM workshop_craftdwarves wc 
    JOIN workshop w ON w.workshop_id = wc.workshop_id
    JOIN dwarves_skill ds ON ds.dwarf_id = wc.dwarf_id
    LEFT JOIN skill s ON s.skill_id = ds.skill_id AND skill.name = w.type
)
workshop_workers AS(
  SELECT wc.workshop_id
       , COUNT(dwarf_id) workers_qty
       , JSON_ARRAYAGG(wc.dwarf_id) worker_ids
       , ROUND(SUM(wds.skill_level)*1.0 / COUNT(dwarf_id), 2) average_worker_skill 
    FROM workshop_craftdwarves wc
    LEFT JOIN workshop_dwarves_skills wds on wds.dwarf_id = wc.dwarf_id
GROUP BY wc.workshop_id, wc.dwarf_id
),
workshop_production_info AS(
  SELECT wp.workshop_id
       , COUNT(wp.product_id) total_quantity_produced
       , SUM(wp.value) total_production_value
       , ( SELECT COUNT(wp.product_id) * 1.0 / COUNT( DISTINCT CAST (wp.production_date AS DATE)) -- (Total qty) / (Days qty)
             FROM workshop_products wp_sub 
            WHERE wp_sup.workshop_id = wp.workshop_id
         ) AS daily_production_rate
       , JSON_ARRAYAGG(wp.product_id) product_ids
    FROM workshop_products wp
GROUP BY wp.workshop_id
),
workshop_materials_info AS(
  SELECT wm.workshop_id,
       , SUM(CASE WHERE wm.is_input THEN wm.quantity ELSE 0 END) input_materials_qty
       , SUM(wm.quanity) total_materials_qty
       , JSON_ARRRAYAGG(wm.material_id) material_ids
    FROM workshop_materials wm
GROUP BY wm.workshop_id
),
workshop_skill_quality_info AS(
  SELECT wp.workshop_id
       , CORR(p.value, wds.skill_level) skill_quality_correlation
    FROM workshop_products wp
    LEFT JOIN products p ON p.product_id = wp.product_id
    LEFT JOIN workshop_dwarves_skills wds ON wds.workshop_id = wp.workshop_id AND wds.dwarf_id = p.created_by
GROUP BY wp.workshop_id
),
workshop_projects_info AS(
  SELECT COUNT(p.project_id)
       , JSON_ARRAYAGG(p.project_id) project_ids
    FROM projects p
   WHERE p.workshop_id IS NOT NULL
GROUP BY p.workshop_id
)
SELECT w.id
     , w.workshop_name
     , w.type workshop_type
     , ww.workers_qty num_craftsdwarves
     , wpi.total_quantity_produced
     , wpi.total_production_value
     , wpi.daily_production_rate
     , ROUND(wmi.input_materials_qty * 1.0 / wpi.total_quantity_produced, 2) value_per_material_unit
     , ROUND((daily_production_rate / 1*(1 + 0.05 * ww.average_worker_skill)*ww.workers_qty), 2) workshop_utilization_percent -- '1' - max production of 1 dwarf with 1 level for 1 day.
     , ROUND((wmi.total_materials_qty - wmi.input_materials_qty) * 1.0 / wmi.input_materials_qty, 2) material_conversion_ratio
     , ww.average_worker_skill average_craftsdwarf_skill
     , wsqi.skill_quality_correlation
     , JSON_OBJECT(
          'craftdwarf_ids', ww.worker_ids,
          'product_ids', wpi.product_ids,
          'material_ids', wmi.material_ids,
          'project_ids', wpji.project_ids
     ) as related_entities
  FROM workshops w
  LEFT JOIN workshop_workers ww on ww.workshop_id = w.id
  LEFT JOIN workshop_production_info wpi on wpi.workshop_id = w.workshop_id
  LEFT JOIN workshop_materials_info wmi on wmi.workshop_id = w.workshop_id
  LEFT JOIN workshop_skill_quality_info wsqi ON wsqi.workshop_id = w.workshop
  LEFT JOIN workshop_projects_info wpji ON wpji.workshop_id = w.workshop_id;
