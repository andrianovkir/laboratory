-- 1. Найдите все отряды, у которых нет лидера.

SELECT * 
  FROM squads
 WHERE leader_id is NULL;

-- 2. Получите список всех гномов старше 150 лет, у которых профессия "Warrior".

SELECT * 
  FROM dwarves
 WHERE age > 150
   AND profession = 'Warrior';

-- 3. Найдите гномов, у которых есть хотя бы один предмет типа "weapon".

 SELECT * 
   FROM dwarves d
  WHERE d.dwarf_id IN (SELECT i.owner_id FROM items i WHERE i.type = 'Weapon');
  
-- 4. Получите количество задач для каждого гнома, сгруппировав их по статусу.

SELECT d.dwarf_id
     , d.name
     , t.status
     , count(t.task_id)
  FROM dwarves d
  JOIN tasks t ON t.assigned_to = d.dwarf_id
  GROUP BY d.dwarf_id, d.name, t.status
  ORDER BY d.dwarf_id;

-- 5. Найдите все задачи, которые были назначены гномам из отряда с именем "Guardians".

SELECT t.task_id
     , t.description
     , t.status
     , d.name
     , s.name
  FROM tasks t 
  JOIN dwarves d ON t.assigned_to = d.dwarf_id
  JOIN squads s ON d.squad_id = s.squad_id
 WHERE s.name = 'Guardians';

-- 6. Выведите всех гномов и их ближайших родственников, указав тип родственных отношений.

SELECT d1.name name
     , r.relationship
     , d2.name
  FROM dwarves d1
  JOIN relationships r on r.dwarf_id = d1.dwarf_id
  JOIN dwarves d2 on d2.dwarf_id = r.related_to;
