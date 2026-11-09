-- Задача 4*: Комплексный анализ торговых отношений и их влияния на крепость

-- Разработайте запрос, анализирующий торговые отношения со всеми цивилизациями, оценивая:
-- - Баланс торговли с каждой цивилизацией за все время
-- - Влияние товаров каждого типа на экономику крепости
-- - Корреляцию между торговлей и дипломатическими отношениями
-- - Эволюцию торговых отношений во времени
-- - Зависимость крепости от определенных импортируемых товаров
-- - Эффективность экспорта продукции мастерских

-- FORTRESSES founded_year
-- PRODUCTS
-- CARAVANS caravan_id, arrival_date, departure_date, civilization_type, fortress_id
-- TRADE_TRANSACTIONS transaction_id, caravan_id, date, fortress_items, caravan_items, value, balance_direction
-- CARAVAN_GOODS goods_id, caravan_id, name, type, quantity, value, material_type, price_fluctuation, original_product_id
-- DIPLOMATIC_EVENTS event_id, caravan_id, type, outcome, date, relationship_change, civilization_type

-- 1. Баланс торговли с каждой цивилизацией за все время.
--    Отношения с цивилизациями: DIPLOMATIC_EVENTS. 
--        outcome              - результат ''
--        relationship_change  - изменение отношения
--        civilization_type    - тип цивилизации
--        date                 - дата события.
--        civilization_type = const + ORDER BY date = история отношений
--    Торговля с цивилизацией: CARAVANS
--        arrival_date - departure_date - время присутсвия каравана
--        civilization_type             - цивилизация каравана
--        TRANSACTIONS (caravan_id)     - сделки с караваном
--        civilization_type = const + TRANSACTIONS = история торговли
-- 2. Влияние товаров каждого типа на экономику крепости. 
--    Экономика крепости: Создаваемая и продаваемая продукция:
--        По всем мастерским: список созданных продуктов, потраченных материалов.
--        По всем караванам: списки покупок/продаж со стоимостью
--    Зависимость от импорта:
--        Товары используемые гномами крепости ('Food', 'Medical', 'Equipment', 'Weapon'...). Можно использовать средния значения или коэффициенты т.к. нет лога расхода.
--        Материалы для производства экспорта. Для расчетов возьмем расходы мастерских и вычислим долю импортных материалов. 
--            Самый простой вариант: вычислись долю импорта в общих тратах. Результат представить умноженным на 10000
--
-- 3. Корреляцию между торговлей и дипломатическими отношениями      
--    Информация о дипломатических отношениях (п.1). 
--         Шкала дипломатических отношений. -100..0..100. 0 - нейтральные взаимоотношения (стартовая точка при первой встрече)
--         relationship_change              - изменение отношений при конкретном событии. (SUM(relationship_change) WHERE date < now()) - текущие взаимоотношения.
--    Информация о торговле
--         Количество транзакций с караванами в заданном интервале - TRANSACTIONS (caravan_id)
-- 4. Эволюцию торговых отношений во времени.
--    Сводная таблица (отчет) по торговле разбитая по кварталам
--
-- 5. Зависимость крепости от определенных импортируемых товаров
--        Зависимость: использование товаров, которые не добываются и не производятся в крепости. И при этом используются в производстве. (п.2)
-- 6. Эффективность экспорта продукции мастерских
--        Информация по производству и продажам из п.2 сгруппированная по типам товаров/мастерским.
--        Вычисляем отношение экспорта к общему обороту товаров данного типа. 

-- fortress_items & caravan_items. Для того, чтобы сделать группировку по типу товара/материала нужно "раскрыть" эти поля и в зависимости от типа подход может отличаться.
-- Возможные варианты:
--     Строка с разделителем: <item_id>:<item_count>;...;<item_id>:<item_count>
--     JSON: [{"item_id":"111", "item_count":"2"}, {"item_id":"123", "item_count":"4"}]
--     Отдельная таблица: TRADE_TRANSACTION_ITEMS (list_id INT, item_id INT, item_count INT);
-- TRADE_TRANSACTION применяется в двух сценариях: 
--     Общая оценка торговли. В этом случае будет достаточно полей value и balance_direction. Тип полей fortress_items и caravan_items не имеет значения.
--     Детальная информация по предметам/типам. В этом случае необходимо "распаковать" строки либо использовать JOIN. 
--         Отдельная таблица будет работать быстрее, чем поиск подстроки, но потребует дополнительных расходов на обработку транзакции, а так же усложнит структуру БД.
--     Выбор будет зависеть от того, как часто нам нужно будет вытаскивать подробную информацию о сделках. 
--     Рамках одного сводного отчета по всей экономике крепости можно обойтись JSON.
-- MATERIALS. Скорее всего, такая таблица в БД есть, т.к. несколько раз упоминается как внешний ключ. Предположим, что структура такая: MATERIALS(material_id INT, name VARCHAR, type VARCHAR, value INT)

WITH fortress_production AS(
  SELECT w.workshop_id
       , w.workshop_type
       , w.fortress_id
       , 'produced' record_type
       , wp.product_id item_id
	   , p.name item_name
       , p.type item_type
       , p.quality item_quality
       , p.value item_value
       , wp.production_date item_date
       , wp.quantity item_quantity
    FROM workshop_products wp
  	JOIN workshops w ON w.workshop_id = wp.workshop_id
    JOIN products  p ON wp.product_id = p.product_id
UNION ALL 
  SELECT w.workshop_id
       , w.workshop_type
       , w.fortress_id
       , 'spent' record_type
       , wm.material_id item_id
       , m.name item_name
       , m.type item_type
       , 0 item_quality
       , m.value item_value
       , null item_date
       , wm.quantity item_quantity
  	FROM workshop_materials wm ON wm.workshop_id = wp.workshop_id
    JOIN materials m ON m.material_id = wm.material_id
    JOIN workshops w ON w.workshop_id = wm.workshop_id
   WHERE wm.is_unput = true
),
fortress_import AS(
    SELECT fp.fortress_id
         , fp.item_type material_type
         , SUM(tid.item_count) total_imported
         , SUM(tid.item_count) * 10000.0 / (SUM(fp.item_quantity)) dependency_score
         , COUNT(DISTINCT c.civilization_type) import_diversity
         , JSON_ARRAYAGG(DISTINCT fp.item_id) AS resource_ids
      FROM fortress_production fp
 LEFT JOIN caravans c ON fp.fortress_id = c.fortress_id
 LEFT JOIN trade_transactions tt ON tt.caravan_id = c.caravan_id
 LEFT JOIN transaction_item_details tid ON (tid.transaction_id = tt.transaction_id AND tid.trade_direction = 'import')
     WHERE fp.record_type = 'spent'
  GROUP BY fp.fortress_id, fp.item_type
--  ORDER BY dependency_score
),
fortress_export AS(
    SELECT fp.fortress_id
         , fp.worshop_type
         , fp.product_type
         , SUM(tid.item_count) total_export
         , SUM(tid.item_count) * 100.0 /SUM(fp.item_quantity) export_ratio,
         , SUM(tid.product_value)*1.0/SUM(fp.item_value) avg_markup            --export_cost/production_cost
         , JSON_ARRAYAGG(DISTINCT fp.workshop_id) workshop_ids
      FROM fortress_production fp
 LEFT JOIN caravans c ON fp.fortress_id = c.fortress_id
 LEFT JOIN trade_transaction tt ON tt.caravan_id = c.caravan_id
 LEFT JOIN transaction_item_details tid ON (tid.transation_id = tt.transaction_id AND tid.trade_direction = 'export')
     WHERE fp.type = 'produced'
  GROUP BY fp.fortress_id, fp.workshop_type, fp.product_type
),
transaction_item_details AS(
    SELECT tt.transaction_id
         , 'export' trade_direction
         , exported.item_count item_count
  			 , export_products.product_id item_id
  			 , export_products.type product_type
         , export_products.value product_value
      FROM trade_transaction tt
CROSS JOIN LATERAL json_to_recordset(tt.fortress_items) AS exported(item_id INT, item_count INT)
 LEFT JOIN products export_products ON export_products.id = exported.item_id

 UNION ALL
    
    SELECT tt.transaction_id
         , 'import' trade_direction
         , imported.item_count item_count
  			 , import_materials.goods_id item_id
  			 , import_materials.material_type item_type
         , import_materials.value product_value
      FROM trade_transaction tt
CROSS JOIN LATERAL json_to_recordset(tt.caravan_items) AS imported(item_id INT, item_count INT)
 LEFT JOIN caravan_goods import_materials ON import_materials.id = imported.item_id
),
fortress_diplomacy_intervals AS(
	SELECT c.fortress_id
       , de.caravan_id
       , de.civilization_type
       , de.date relation_start
       , LEAD(de.date) OVER (PARTITION BY c.fortress_id, de.civilization_type, c.caravan_id ORDER BY de.date) AS relation_end
       , de.relationship_change relationship
    FROM diplomatic_events de
    JOIN caravan c ON c.caravan_id = de.caravan_id
),
fortress_civilization_history AS(
    SELECT fdi.fortress_id
         , fdi.civilazation_type
         , fdi.relationship
  			 , (CASE WHEN fdi.relationship = 'Favorable' THEN 1 
                 WHEN fdi.relationship = 'Unfavorable' THEN -1
                 ELSE 0 END) relationship_val
         , (CASE WHEN fdi.end_time IS NULL then 1 ELSE 0 END) AS is_current_relationship
         , fdi.relation_start
         , fdi.relation_end
         , SUM (tt.value) total_interval_trade
         , SUM (CASE WHEN tt.balance_direction = 'EXPORT' THEN tt.value WHEN tt.balance_diretion = 'IMPORT' THEN -1*tt.value ELSE 0) total_interval_balance
         , COUNT(c.caravan_id) total_caravans
      FROM fortress_diplomacy_intervals fdi 
 LEFT JOIN trade_transactions tt ON tt.caravan_id = fdi.caravan_id -- caravan determine fortress_id and civilization_type
                                    AND tt.date >= fdi.relation_start
                                    AND (tt.date < fdi.relation_stop OR fdi.relation_stop IS NULL)
),
fortress_civilization_trade AS(
    SELECT fch.fortress_id
         , fch.civilization_type
  		   , COUNT(fch.total_caravans) total_caravans
         , SUM(fch.total_interval_trade) total_trade_value
         , SUM(fch.total_interval_balance) trade_balance
         , FIRST_VALUE(fch.relationship) OVER (PARTITION BY fch.fortress_id, fch.civilization_type ORDER BY is_current DESC) AS trade_relationship
         , CORR(fch.total_interval_balance, fch.relationship_val) diplomatic_correlation
         , JSON_ARRAYAGG(SELECT caravan_id FROM caravans WHERE fortress_id = fch.fortress_id AND civilization_type = fch.civilization_type) caravan_ids
      FROM fortress_civilization_history fch
  GROUP BY fch.civilization_type
),
fortress_diplomacy AS(
  SELECT de.event_id
       , c.caravan_id
       , c.fortress_id
       , de.type
       , de.outcome
       , de.date
       , de.relationship_change
       , de.civilization_type
    FROM diplomatic_events de
    JOIN caravan c ON c.carvan_id = de.caravan_id
ORDER BY de.date
)
SELECT f.fortress_id
     , f.founded_year
     , f.name
     , f.population
     , JSON_OBJECT(
           'civilization_data',
           JSON_ARRAYAGG(SELECT JSON_OBJECT(
                                    'civilization_type', fct.civilization_type,
                                    'total_caravans', fct.total_caravans,
               						'total_trade_value', fct.total_trade_value,
    								'trade_balance', fct.trade_balance,
    								'trade_relationship', fch.trade_relationship,
    								'diplomatic_correlation', diplomatic_correlation,
    								'caravan_ids', caravan_ids)
                           FROM fortress_civilization_trade fct
                          WHERE fct.fortress_id = f.fortress_id
                        ) AS civilization_trade_data
                   
       ) AS civilization_data
     , JSON_OBJECT(
           'critical_import_dependencies', 
           JSON_ARRAYAGG(
           		SELECT JSON_OBJECT(
                           'material_type', fi.material_type,
                           'dependency_score', fi.dependency_score,
                           'total_imported', fi.total_imported,
                           'import_diversity', fi.import_diversity,
                           'resource_ids', fi.resource_ids)
                FROM fortress_import fi
               WHERE fi.fortress_id = f.fortress_id
           ) AS resource_dependency
       ) AS critical_import_dependencies
     , JSON_OBJECT(
           'export_effectiveness',
           JSON_ARRAYAGG(
              SELECT JSON_OBJECT(
                         'workshop_type', fe.workshop_type,
                         'product_type', fe.product_type,
                         'export_ratio', fe.export_ratio,
                         'avg_markup', fe.avg_markup,
                         'workshop_ids', fe.workshop_ids)
                FROM fortress_export fe
               WHERE fe.fortress_id = f.fortress_id
            ) export_effectiveness
       ) AS export_effectiveness
     , JSON_OBJECT(
           'trade_timeline',
           JSON_ARRAYAGG(quater
               SELECT JSON_OBJECT(
                          'year', EXTRACT(YEAR FROM tt.date),
                          'quarter', EXTRACT(QYARTER FROM tt.date),
                          'quarterly_value', SUM(tt.value),
                          'quarterly_balance', SUM(CASE WHEN tt.balance_direction = 'EXPORT' THEN tt.value ELSE -1*tt.value),
                          'trade_diversity', COUNT(DISTINCT c.civilization_type)
               	 )
                 FROM trade_transactions tt
                 JOIN caravan c ON c.caravan_id = tt.caravan_id
                WHERE c.fotress_id = f.fortress_id
             GROUP BY EXTRACT (YEAR FROM tt.date),
                      EXTRACT (QUARTER FROM tt.date),
                      tt.caravan_id
             ORDER BY EXTRACT (YEAR FROM tt.date),
                      EXTRACT (QUARTER FROM tt.date)
           ) AS trade_growth
		    ) AS trade_timeline     
  FROM fortresses f
GROUP BY f.fortress_id
     , f.founded_year
     , f.name
     , f.population;
