-- Задача 5*: Многофакторный анализ угроз и безопасности крепости

-- Разработайте запрос, который комплексно анализирует безопасность крепости, учитывая:
-- - Историю всех атак существ и их исходов
-- - Эффективность защитных сооружений
-- - Соотношение между типами существ и результативностью обороны
-- - Оценку уязвимых зон на основе архитектуры крепости
-- - Корреляцию между сезонными факторами и частотой нападений
-- - Готовность военных отрядов и их расположение
-- - Эволюцию защитных способностей крепости со временем

-- CREATURES creature_id, name, type, threat_level, active, estimated_population
-- 					 CREATURE_ATTACKS attack_id, creature_id, date, casualties, enemy_casualties, location_id, outcome,
--                            defense_structures_used, military_response_time_minutes
-- 					 CREATURE_SIGHTINGS sighting_id, creature_id, location, date, witness_id
--           CREATURE_TERRITORIES territory_id, creature_id, area, danger_level, distance_to_fortress
-- FORTRESS fortress_id
--                LOCATIONS location_id, fortress_id, zone_id, name, zone_type, fortification_level, wall_integrity, trap_density, choke_points
--                          DEFENSE_STRUCTURES location_id, type
--                          MILITARY_STATIONS station_id, squad_id, location_id
--                SQUAD_MOVEMENT squad_id, zone_id
--                MILITARY_COVERAGE_ZONES squad_id, zone_id, reaction_time
-- MILITARY_SQUAD squad_id, name, formation_type, leader_id, fortress_id
--     SQUAD_MEMBERS squad_id, dwarf_id, join_date, role, exit_date, exit_reason                                
--         DWARF_SKILLS dwarf_id, skill_id, level, date
--             SKILLS skill_id, category = 'Combat'
-- SECURITY_RECOMMENDATIONS recommendation_id, 
-- WEATHER_RECORDS record_id, date
-- MOON_PHASES record_id, date, phase

-- Возможно, не хватает информации о разрушении защитных сооружений. 
-- Для того, чтобы рассчитать параметры атаки/успешность обороны используем в качестве ведущей таблицы CREATURE_ATTACKS. 
--     Проблема: нет данных по дате строительства фортификаций. Придется считать, что все, связанное с location уже существовало на момент атаки.
-- Коэффициент корреляции может быть рассчитан двумая способами: 
--     * Успешность атак в зависимости от внешних обстоятельств.
--     * Количество атак в зависимости от внешних обстоятельств.
-- Непонятно отношение Zones и Locations.
--     Описание: Locations - места в крепости. 
--               Zones - отдельно не описаны. Есть ссылки 
--                  Project_Zones (zone_id(PK) - первичный ключ). Описание: Связывает проекты с зонами крепости (n:m) (Многие ко многим, т.е. должен быть и внешний ключ)
--                  Military_Coverage_Zones. Связывают отряды с зонами и временем реакции (n:m)
--     Примеры: 
--         military_readiness_assessment -> response_coverage -> zone_id. (Из Military_Coverage_Zones)
--         vulnerability_analysis -> zone_id|zone_name ("Eastern Gate")
--         defense_effectiveness -> defense_type ("Trap Corridor")

WITH fortress_threatment AS(
    SELECT c.type creature_type
         , AVG(c.threat_level) threat_level
         , SUM(c.estimated_population) estimated_numbers
         , MAX(cs.date) last_sighting_date
         , AVG(ct.distance_to_fortress) territory_proximity
         , JSON_ARRAYAGG(creature_id) creature_ids
      FROM creatures c
 LEFT JOIN creature_sightings cs ON cs.creature_id = c.creature_id
 LEFT JOIN creature_territories ct ON ct.creature_id = c.creature_id
  GROUP BY c.type
),
fortress_defence_history AS(
    SELECT c.creature_id
         , c.name
         , c.type creature_type
         , c.threat_levtl
         , c.estimated_population
         , ca.attack_id
         , ca.location_id
         , ca.date
         , ca.casualties
         , ca.enemy_casualties
         , ca.outcome                   -- 'defend_success', 'defend_fail'
         , ca.defense_structures_used   -- flag or list [structure_id, structure_id]
         , ca.military_response_time_minutes
         , l.zone_id
		 , l.location_id
         , l.fortress_id
         , l.zone_type
         , l.name zone_name
         , l.fortification_level
         , l.wall_integrity       -- 0..1
         , l.trap_density         -- 0..1
         , l.choke_points         -- 1..n
      FROM creatures c
      JOIN creature_attacks ca ON ca.creature_id = c.creature_id
 LEFT JOIN locations l ON l.location_id = ca.location_id
),
attack_by_type_analytics AS(
    SELECT fdh.forterss_id
         , fdh.creature_type
         , fdh.location_id
         , ROUND(SUM(CASE WHEN fdh.outcome = 'defend_success' THEN 1 ELSE 0 END) * 1.0 / COUNT(fdh.attack_id)) creature_type_defend_success_rate
      FROM fortress_defence_history fdh
  GROUP BY fdh.fortress_id, fdh.locatio_id, fdh.creature_type
),
location_defence_overview AS(
    SELECT fdh.fortress_id
         , fdh.location_id
         , fdh.zone_id
         , fdh.zone_name
         , fdh.zone_type
         , fdh.fortification_level
         , COUNT(DISTINCT fdh.creature_id) unique_attakers
         , COUNT(DISTINCT fdh.attack_id) total_attacks
         , SUM(CASE WHEN fdh.outcome = 'defend_success' THEN 1 ELSE 0 END) * 1.0 / COUNT(DISTINCT fdh.attack_id) defend_success_rate
         , SUM(CASE WHEN fdh.outcome = 'defend_fail' THEN 1 ELSE 0 END) historical_breaches
         , ROUND(AVG(fdh.enemy_casualties), 2) avg_enemy_casualties
         , ROUND(AVG(fdh.military_response_time_minutes)) military_response_time
         , CORR(fdh.creature_type, creature_type_defend_success_rate) defend_from_creature_corr -- Expand creature type into numbered option (enum)
         , CORR(aea.agg_weather_coeff, aea.attacks_count) attack_by_weather_corr
      FROM fortress_defence_history fdh
 LEFT JOIN attack_by_type_analytics ata ON ata.location_id = fdh.location_id
 LEFT JOIN attack_by_env_analytics aea ON aea.location_id = fdh.location_id
  GROUP BY fdh.fortress_id, fdh.location_id, fdh.location_name
),
zone_defence_overview AS(
    SELECT ldo.fortress_id
         , ldo.zone_id
         , ldo.zone_name
         , ldo.zone_type
         , SUM(ldo.total_attacks) total_attacks
         , SUM(ldo.historical_breaches) historical_breaches
         , ROUND(1 - (AVG(ldo.wall_integrity) + AVG(ldo.trap_density) + AVG(ldo.choke_points)*0.1)/3 , 2) vulnerability_score
         , MAX(mcz.reaction_time) military_response_time
         , ROUND(AVG(ldo.defend_from_creature_corr), 2) defence_from_creature_corr
         , ROUND(AVG(ldo.attack_by_weather_corr), 2) attack_by_weather_corr
         , JSON_OBJECT(
               'structure_ids', JSON_ARRAYAGG(ds.structure_id),
               'squad_ids', JSON_ARRAYAGG(mcz.squad_id)
           ) AS defence_coverage
      FROM location_defence_overview ldo
 LEFT JOIN military_coverage_zone mcz ON mcz.zone_id = z.zone_id
 LEFT JOIN defense_structures ds ON ds.location_id = ldo.location_id
  GROUP BY ldo.fortress_id, ldo.zone_id, ldo.zone_name, ldo.zone_type
),
defence_structure_effectiveness AS(
    SELECT ldo.fortress_id
         , ds.type defense_type
         , ROUND(AVG(ldo.defend_success_rate)*100, 2) effectiveness_rate
         , ROUND(AVG(ldo.avg_enemy_casualties), 1) avg_enemy_casualties
         , JSON_ARRAYAGG(ds.structure_id) structure_ids
      FROM defense_structure ds
 LEFT JOIN location_defence_overview ldo ON ldo.location_id = ds.location_id
  GROUP BY ldo.fortress_id, ds.type
),
current_dwarf_skills AS(
	  SELECT ds.dwarf_id
         , ds.skill_id
         , MAX(ds.level) skill_level
         , s.category
      FROM dwarf_skills ds
      JOIN skills s ON s.skill_id = ds.skill_id
  GROUP BY ds.dwarf_id, ds.skill_id
),
military_readyness AS(
		SELECT l.fortress_id
         , s.squad_id
         , s.name
         , 0.0 readiness_score  --  ?? 
         , SUM(CASE WHEN sm.exit_date IS NULL THEN 1 ELSE 0 END) active_members
         , AVG((SELECT MAX(skill_level) FROM current_dwarf_skills cds WHERE cds.dwarf_id = sm.dwarf_id AND cds.category = 'Combat')) avg_squad_combat_skill
         , 0.0 combat_effectiveness  --  ??
         , (SELECT JSON_ARRAYAGG( 
                       JSON_OBJECT(
                           'zone_id', mcz.zone_id
                           'response_time', mcz.reaction_time
                       )
                   )
             FROM military_coverage_zone mcz
            WHERE mcz.squad_id = ms.squad_id
           ) AS response_coverage
      FROM military_stations ms
      JOIN locations l ON l.location_id = ms.location_id
 LEFT JOIN military_squads s ON s.squad_id = ms.squad_id
 LEFT JOIN squad_members sm ON sm.squad_id = s.squad_id
 GROUP BY l.fortress_id, ms.squad_id
),
security_evolution AS (
		SELECT fdh.fortress_id
         , EXTRACT(YEAR FROM fdh.date) as year
         , ROUND(SUM(CASE WHEN fdh.outcome = 'defend_success' THEN 1 ELSE 0 END) * 100.0 / COUNT(fdh.attack_id)) defense_success_rate
         , COUNT(fdh.attack_id) total_attacks
         , SUM(fdh.casualties) casualties
         , LAG(ROUND(SUM(CASE WHEN fdh.outcome = 'defend_success' THEN 1 ELSE 0 END) * 100.0 / COUNT(fdh.attack_id))) OVER (PARTITION BY fdh.fortress_id ORDER BY EXTRACT(YEAR FROM ldo.date)) 
           - ROUND(SUM(CASE WHEN fdh.outcome = 'defend_success' THEN 1 ELSE 0 END) * 100.0 / COUNT(fdh.attack_id)) year_over_year_improvement
      FROM fortress_defence_history fdh
  GROUP BY fdh.fortress_id, EXTRACT(YEAR FROM fdh.date)
),
environment_log AS(
	  SELECT wr.record_id
         , 'weather' env_type
         , wr.type weather_type     -- 'sun','rain','fog'...
         , (CASE WHEN wr.type = 'sun' THEN 10
                 WHEN wr.type = 'rain' THEN 20
                 WHEN wr.type = 'fog' THEN 30
--               ..
                 ELSE 0 END) AS weather_coeff
         , wr.date weather_start
         , LEAD(wr.date) OVER (ORDER BY wr.date) weather_end
      FROM weather_records wr
 UNION ALL
    SELECT mp.record_id
         , 'moon' env_type
         , mp.type weather_type -- 'full','half','quarter','no'
  		   , (CASE WHEN wr.type = 'full' THEN 1
                 WHEN wr.type = 'half' THEN 2
                 WHEN wr.type = 'quarter' THEN 3
   						   WHEN wr.type = 'no' THEN 4
                 ELSE 0 END) AS weather_coeff
         , mp.date weather_start
         , LEAD(mp.date) OVER (ORDER BY mp.date) weather_end
      FROM moon_phases mp
),
environment_timeline AS(
    SELECT el.date itv_start
         , LEAD(el.date) OVER (ORDER BY el.date) itv_end
      FROM environment_log el
),
environment_intervals AS(
    SELECT et.itv_start
         , et.itv_end
         , STRING_AGG(el.type || ': ' || el.val, ', ') agg_weather
         , SUM(el.weather_coeff) agg_weather_coeff
      FROM environment_timeline et
      JOIN environment_log el ON el.start_date <= et.itv_start
                             AND el.end_date > et.itv_start OR el.end_date IS NULL
  GROUP BY et.itv_start, et.itv_end
),
attack_by_env_analytics AS(
    SELECT et.itv_start
         , et.itv_end
         , et.weather_agg
         , et.agg_weather_coeff
         , ca.location_id
         , COUNT(DISTINCT ca.attack_id) attacks_count
      FROM environment_intervals ei
      JOIN creature_attacks ca ON ca.date >= ei.itv_start AND ca.date < ei.itv_date
  GROUP BY et.itv_start, et.itv_end, ca.location_id
)
SELECT SUM(se.total_attacks) total_recorded_attacks
     , (SELECT COUNT(DISTINCT ca.creature_id) FROM creature_attacks ca WHERE ca.location_id IN (SELECT location_id FROM locations WHERE fortress_id = se.fortress_id)) unique_attackers
     , AVG(se.defense_success_rate) overall_defence_success_rate
     , JSON_OBJECT(
           'threat_assessment', 
           JSON_OBJECT(
               'current_threat_level',  (CASE WHEN ft.threat_level IS NULL OR AVG(ft.threat_level) = 0 THEN 'Nothing' 
                                              WHEN AVG(ft.threat_level) < 3 THEN 'Low' 
                                              WHEN AVG(ft.threat_level) < 5 THEN 'Moderate'
                                              ELSE 'High' END),
           	   'active_threats', 
               JSON_ARRAYAGG(
                   JSON_OBJECT(
                       'creature_type', ft.creature_type,
                       'threat_level', ft.threat_level,
                       'last_sighting_date', ft.last_sighting_date,
                       'territory_proximity', ft.territory_proximity, 
                       'estimated_numbers', ft.estimated_numbers,
                       'creature_ids', ft.creature_ids
                   )
               )
           ),
           'vulnerability_analysis',
           (SELECT JSON_ARRAYAGG(
           		  JSON_OBJECT(
               		 'zone_id', zdo.zone_id,
                   'zone_name', zdo.zone_name,
                   'vulnerability_score',zdo.vulnerability_score, 
                   'historical_breaches', zdo.historical_breaches,
                   'fortification_level', zdo.fortification_level,
                   'military_response_time', zdo.military_response_time,
                   'defence_from_creature_corr', zdo.defence_from_creature_corr,
                   'attack_by_weather_corr', zdo.attack_by_weather_corr
                   'defense_coverage', JSON_OBJECT(
                        'structure_ids', zdo.structure_ids,
                        'squad_ids', zdo.squad_ids
                    )
                 )
                 )
                 FROM zone_defence_overview zdo
                WHERE zdo.fortress_id = ft.fortress_id
             ORDER BY zdo.vulnerability_score DESC LIMIT 2
           ),
           'defence_effectiveness',
       		 ( SELECT JSON_ARRAYAGG(
           	    JSON_OBJECT(
                    'defence_type', dse.defence_type,
                    'effectiveness_rate', dse.effectiveness_rate,
                    'avg_enemy_casuatlties', dse.avg_enemy_casualties,
                    'structure_ids', dse.structure_ids
                   )
               )
                 FROM defence_structure_effectiveness dse
                WHERE dse.fortress_id = ft.fortress_id
             ORDER BY dse.effectiveness_rate DESC LIMIT 2
           ),
           'military_readiness',
           (SELECT JSON_ARRAYAGG(
           		  JSON_OBJECT(
                    'squad_id', mr.squad_id,
                    'squad_name', mr.squad_name,
                    'readiness_score', mr.readyness_score,
                    'active_members', mr.active_members,
                    'avg_combat_skill', mr.avg_combat_skill,
                    'combat_effectiveness', mr.combat_effectiveness,
                    'response_coverage', mr.response_coverage
                 )
             )
                 FROM military_readyness mr
                WHERE mr.fortress_id = ft.fortress_id
           ),
           'security_evolution',
           (SELECT JSON_ARRAYAGG(
           		JSON_OBJECT(
                   'year', se.year,
                   'defense_success_rate', se.defense_success_rate,
                   'total_attacks', se.total_attacks,
                   'casualties', se.casualties,
                   'year_over_year_improvement', se.year_over_year_improvement
                )
              )
            FROM security_evolution se
           WHERE se.fortress_id = ft.fortress_id
        ORDER BY se.year)
     ) AS security_analysis 
FROM fortress_threatment ft
GROUP BY ft.fortress_id;
