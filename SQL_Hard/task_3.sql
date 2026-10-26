-- Задача 2: Получение данных о гноме с навыками и назначениями

-- SKILLS skill_id; DWARF_SKILLS dwarf_id, skill_id;                                      -- Навыки
-- DWARF_ASSIGNMENTS assignment_id, dwarf_id;                                             -- Назначения
-- MILITARY_SQUADS squad_id, leader_id, fortress_id; SQUAD_MEMBERS squad_id, dwarf_id;    -- Отряды
-- EQUIPMENT equipment_id; DWARF_EQUIPMENT dwarf_id, equipment_id;                        -- Снаряжение

SELECT d.dwarf_id
     , d.name
     , d.age
     , d.profession
     , JSON_OBJECT(
          'skill_ids', (
              SELECT JSON_ARRAYAGG(ds.skill_id)
                FROM dwarf_skills ds WHERE (ds.dwarf_id = d.dwarf_id)
          ),
          'assignment_ids', (
              SELECT JSON_ARRAYAGG(da.assignment_id)
                FROM dwarf_assignments da WHERE (da.dwarf_id = d.dwarf_id)
          ),
          'squads_ids', (
              SELECT JSON_ARRAYAGG(sm.squad_id)
                FROM squad_members sm WHERE (sm.dwarf_id = d.dwarf_id)
          ),
          'equipment_ids', (
              SELECT JSON_ARRAYAGG(de.equipment_id)
                FROM dwarf_equipment de WHERE (de.dwarf_id = d.dwarf_id)
          )
     ) AS related_entities
  FROM dwarves d



-- Задача 3: Данные о мастерской с назначенными рабочими и проектами

-- WORKSHOPS workshop_id, fortress_id;                                                       -- Мастерские
-- WORKSHOP_CRAFTSDWARVES workshop_id, dwarf_id; DWARVES dwarf_id                            -- Назначенные гномы
-- PROJECTS project_id, workshop_id                                                          -- Проекты
-- WORKSHOP_MATERIALS workshop_id, material_id (т. MATERIALS не описана)                     -- Используемые материалы
-- WORKSHOP_PRODUCTS workshop_id, product_id; PRODUCTS product_id, material_id, workshop_id; -- Производимые ресурсы

SELECT w.workshop_Id
     , w.name
     , w.type
     , w.quality
     , JSON_OBJECT(
          'craftsdwarf_ids', ( 
              SELECT JSON_ARRAYAGG(wc.dwarf_id)
                FROM workshop_craftdwarves wc WHERE (wc.workshop_id = w.workshop_id)
          ),
          'project_ids', (
              SELECT JSON_ARRAYAGG(p.project_id)
                FROM projects p WHERE (p.workshop_id = w.workshop_id)
          ),
       	  'input_materials_ids', (
              SELECT JSON_ARRAYAGG(wm.material_id)
                FROM workshop_materials wm WHERE (wm.workshop_id = w.workshop_id)
          ),
          'output_product_ids', (
              SELECT JSON_ARRAYAGG(wp.product_id)
                FROM workshop_products wp WHERE (wp.workshop_id = w.workshop_id)
          )
     ) AS related_entities
  FROM workshops w;

-- Задача 4: Данные о военном отряде с составом и операциями

-- MILITARY_SQUADS squad_id;                 -- Отряды
-- SQUAD_MEMBERS squad_id, dwarf_id;         -- Члены отряда
-- SQUAD_EQUIPMENT squad_id, equipment_id;   -- Снаряжение отряда
-- SQUAD_OPERATIONS operation_id, squad_id;  -- Операции отряда
-- SQUAD_TRAINING schedule_id, squad_id;     -- Тренировки отряда
-- SQUAD_BATTLES report_id, squad_id;        -- Отчеты о битвах отряда

SELECT s.squad_id
     , s.name
     , s.formation_type
     , s.leader_id
     , JSON_OBJECT(
          'members_ids', (
              SELECT JSON_ARRAYAGG(sm.dwarf_id)
                FROM squad_members sm WHERE (sm.squad_id = s.squad_id)
          ),
          'equipment_ids', (
              SELECT JSON_ARRAYAGG(se.equpment_id)
                FROM squad_equipment se WHERE (se.squad_id = s.squad_id)
          ),
          'operation_ids', (
              SELECT JSON_ARRAYAGG(so.operation_id)
                FROM squad_operations so WHERE (so.squad_id = s.squad_id)
          ),
       	  'training_schedule_ids', (
              SELECT JSON_ARRAYAGG(st.schedule_id)
                FROM squad_training st WHERE (st.squad_id = s.squad_id)
          ),
          'battle_report_ids', (
              SELECT JSON_ARRAYAGG(sb.report_id)
                FROM squad_battles sb WHERE (sb.squad_id = s.squad_id)
          )
     ) as related_entities
  FROM military_squads s;
