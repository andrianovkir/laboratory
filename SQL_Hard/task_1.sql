-- 1. Получить информацию о всех гномах, которые входят в какой-либо отряд, вместе с информацией об их отрядах.
SELECT dwarves.dwarf_id dwarf_id
     , dwarves.name dwarf_name
     , dwarves.age dwarf_age
     , dwarves.profession dwarf_profession
     , squads.squad_id dwarf_squad
     , squads.name squad_name
     , squads.mission squad_mission
  FROM dwarves 
  JOIN squads on dwarves.squad_id = squads.squad_id;   -- JOIN (INNER) filters dwarves without squad (squad_id == null)
-- WHERE squads.name = ?;                              -- OPTIONAL restriction for information about specific squad
-- Рефлексия: Обычный запрос с JOIN. LEFT JOIN так же покажет гномов без отряда. 
--            Такие запросы хорошо работают с индексами (dwarves.dwarf_id, squads.squad_id - первичные ключи, dwarves.squad_id - внешний ключ)

-- 2. Найти всех гномов с профессией "miner", которые не состоят ни в одном отряде.
SELECT * 
FROM dwarves
WHERE profession = 'miner'
  AND squad_id is null;
-- Рефлексия: В данном случае, так как гном может состоять только в одном отрядке (dwarves.squad_id), достаточно проверить только это поле. 
--            В случае, если бы гном мог входить в несколько отрядов (н-р т. dwarves_squads), 
--            то потребовался бы подзапрос (not exists (select squad_id from dwarves_squads where dwarf_id = dwarves.dwarf_id)). 

-- 3. Получить все задачи с наивысшим приорите, которые находятся в статусе "pending".
-- All tasks with highest priority in 'pending' status. 

-- Var A.
SELECT * FROM tasks
WHERE status = 'pending'
  AND priority = (SELECT MAX(priority) from tasks where status = 'pending');
  
-- Var B. 
WITH ranked_tasks AS
(
	SELECT *, DENSE_RANK() OVER (ORDER BY priority DESC) as rnk
  FROM tasks
  WHERE status = 'pending'
)
SELECT * FROM ranked_tasks 
WHERE rnk = 1;
  
-- Рефлексия: 
--    Базовый запрос SELECT * FROM tasks WHERE status = 'pending' вернет все задачи в необходимом статусе. 
--        Нужно вычислить наивысший приоритет и отфильтровать те, приоритет которых ниже.
--    Var A. Условие priority = (SELECT MAX(priority) from tasks) работает довольно быстро(один проход по таблице O(N)) и не требует дополнительной памяти.
--        Можно добавить индекс по полю priority для получения константного времени O(1)
--        Проблема: может вернуть приоритет выше чем у любой задачи в статусе 'pending'. Тогда общий запрос ошибочно не выведет записей. 
--        Решение: продублировать условие в подзапросе: priority = (SELECT MAX(priority) from tasks where status = 'pending')
--    Var B. Выбрать все задачи в статусе 'pending' и ранжировать их по приоритету. После чего выбрать задачи с меньшим рангом(1). 
--        Этот запрос работает медленнее Var A из-за необходимости сортировки записей и требует памяти для хранения всей ранжированной таблицы. 
--        Но в случае, если дальнейшая обработка может учитывать записи с более низким приоритетом, он может быть использован. (Например, в виде view)

-- 4. Для каждого гнома, который владеет хотя бы одним предметом, получить количество предметов, которыми он владеет.

WITH owned_items AS(
	SELECT count(item_id) qty
       , owner_id 
    FROM items
	GROUP BY owner_id)
SELECT dwarves.dwarf_id
     , dwarves.name
     , owned_items.qty
  FROM dwarves
  JOIN owned_items ON owned_items.owner_id = dwarves.dwarf_id;

-- Рефлексия: сначала использовал 'простой' вариант без WITH, но заметил, что в этом случае группировка будет происходить в том числе для повторяющихся записей:
--            если для одного гнома есть несколько предметов, то записи будут дублированы перед группировкой. Вариант с WITH решает эту проблему. 
--            JOIN(INNER) отсекает гномов без предметов и предметы без владельца (если такие есть)

-- 5. Получить список всех отрядов и количество гномов в каждом отряде. Также включите в выдачу отряды без гномов.

WITH dwarves_in_squads AS(
	SELECT squad_id
       , count(dwarf_id) qty
    FROM dwarves
    GROUP BY squad_id
)
SELECT squads.squad_id
     , squads.name
     , squads.mission
     , coalesce(dwarves_in_squads.qty, 0)
FROM squads
LEFT JOIN dwarves_in_squads on dwarves_in_squads.squad_id = squads.squad_id;

-- Рефлексия: задача похожа на 5, но в данном случае используем LEFT JOIN для добавления в список отрядов в которых нет гномов. 
--            Так же используем функцию coalesce, чтобы в дальнейшей логике не обрабатывать отдельно null-значения и работать с полем как с целочисленным

-- 6. Получить список профессий с наибольшим количеством незавершённых задач ("pending" и "in_progress") у гномов этих профессий.

WITH ranked_prof_tasks AS(
	SELECT dwarves.profession
  	   , count(tasks.task_id) qty
    	 , DENSE_RANK() OVER (ORDER BY count(tasks.task_id) DESC) as rnk
    FROM tasks
    JOIN dwarves ON tasks.assigned_to = dwarves.dwarf_id
   WHERE tasks.status in ('pending', 'in_progress')
   GROUP BY dwarves.profession
)
SELECT ranked_prof_tasks.profession
     , ranked_prof_tasks.qty
  FROM ranked_prof_tasks
 WHERE rnk = 1;

-- Рефлексия: совмещение подходов 3 и 4 задач. Вариант с функцией MAX в данном случае подходит хуже чем ранжирование, 
--            так как СУБД придется дважды работать с объединением dwarves-tasks: для вычисления MAX и для поиска профессии.

-- 7. Для каждого типа предметов узнать средний возраст гномов, владеющих этими предметами.

SELECT items.type item_type
     , AVG(dwarves.age) avg_dwarf_age
FROM items JOIN dwarves ON items.owner_id = dwarves.dwarf_id
GROUP BY items.type;

-- Рефлексия: математическое "Среднее", которое возвращает функция AVG, на мой взгляд не очень подходит для работы с возрастом. 
--            Возможно, в данном случае было бы правильно округлить значение до одного знака после точки или использовать медианное значение.
--            Выбор варианта зависит от того, как будет использоваться результат запроса в дальнейшем. 

-- 8. Найти всех гномов старше среднего возраста (по всем гномам в базе), которые не владеют никакими предметами.

WITH dwarves_aged AS(
	SELECT dwarves.dwarf_id dwarf_id
       , dwarves.name name
       , dwarves.age age
       , AVG(dwarves.age) OVER () avg_age
    FROM dwarves
)
SELECT dwarf_id
     , name 
     , age
  FROM dwarves_aged
 WHERE age > avg_age
   AND NOT EXISTS(SELECT 1 FROM items WHERE items.owner_id = dwarves_aged.dwarf_id);

-- Рефлексия: задача похожа на 7, но вместо аггрегатной функции AVG используется оконная функция AVG() OVER(), 
--            чтобы сохранить среднее значение для дальнейшей фильтрации. AVG() OVER() не создает дополнительной нагрузки, 
--            так как рассчитывается не для каждой строки, а один раз после вычитки данных. Кроме того позволяет избежать GROUP BY
--            который в данном случае не нужен. 
--            Для отсечения гномов, владеющих предметами использован подзапрос с NOT EXISTS, так как этот вариант более оптимален по сравнению с LEFT JOIN
