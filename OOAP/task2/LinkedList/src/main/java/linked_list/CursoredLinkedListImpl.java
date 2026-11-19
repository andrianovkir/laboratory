package linked_list;

public class CursoredLinkedListImpl<T> extends CursoredLinkedList<T>
{
    private static class ListNode<T>
    {
        private ListNode(T value, ListNode<T> nextNode)
        {
            this.value = value;
            this.nextNode = nextNode;
        }

        private T value;
        private ListNode<T> nextNode;
    }

    private static class Cursor<T>
    {
        private int listSize;
        private boolean isInitialized;

        private int lastPutStatus;
        private int lastGetStatus;
        private int lastRemoveStatus;
        private int lastFindStatus;
        private int lastReplaceStatus;

        private ListNode<T> head;
        private ListNode<T> current;
        private ListNode<T> previous;

        private Cursor()
        {
            listSize = 0;
            isInitialized = false;

            lastPutStatus = CursoredLinkedList.PUT_STATUS_NIL;
            lastGetStatus = CursoredLinkedList.GET_STATUS_NIL;
            lastRemoveStatus = CursoredLinkedList.REMOVE_STATUS_NIL;
            lastFindStatus = CursoredLinkedList.FIND_STATUS_NIL;
            lastReplaceStatus = CursoredLinkedList.REPLACE_STATUS_NIL;
        }

        private void clear()
        {
            listSize = 0;
            isInitialized = false;

            head = null;
            current = null;
            previous = null;

            lastPutStatus = CursoredLinkedList.PUT_STATUS_NIL;
            lastGetStatus = CursoredLinkedList.GET_STATUS_NIL;
            lastRemoveStatus = CursoredLinkedList.REMOVE_STATUS_NIL;
            lastFindStatus = CursoredLinkedList.FIND_STATUS_NIL;
            lastReplaceStatus = CursoredLinkedList.REPLACE_STATUS_NIL;
        }
    }

    private final Cursor<T> cursor = new Cursor<>();

    @Override
    public T get()
    {
        if(isValue())
        {
            cursor.lastGetStatus = CursoredLinkedList.GET_STATUS_OK;
            return cursor.current.value;
        }
        else
        {
            cursor.lastGetStatus = CursoredLinkedList.GET_STATUS_ERR;
            return null;
        }
    }

    @Override
    public void putLeft(T value)
    {
        if(isValue())
        {
            ListNode<T> node = new ListNode<>(value, cursor.current);
            node.nextNode = cursor.current;
            cursor.previous = node;

            if(isHead())
            {
                cursor.head = node;
            }
            else
            {
                cursor.previous.nextNode = node;
            }
            cursor.listSize++;

            cursor.lastPutStatus = CursoredLinkedList.PUT_STATUS_OK;
        }
        else
        {
            cursor.lastPutStatus = CursoredLinkedList.PUT_STATUS_ERR;
        }
    }

    @Override
    public void putRight(T value)
    {
        if(isValue())
        {
            ListNode<T> node = new ListNode<>(value, cursor.current);
            node.nextNode = cursor.current;
            cursor.previous.nextNode = node;
            cursor.listSize++;

            cursor.lastPutStatus = CursoredLinkedList.PUT_STATUS_OK;
        }
        else
        {
            cursor.lastPutStatus = CursoredLinkedList.PUT_STATUS_ERR;
        }
    }

    @Override
    public void putToEmpty(T value)
    {
        if(!isValue())
        {
            ListNode<T> node = new ListNode<>(value, null);
            cursor.head = node;
            cursor.current = node;
            cursor.previous = null;
            cursor.isInitialized = true;
            cursor.listSize++;

            cursor.lastPutStatus = CursoredLinkedList.PUT_STATUS_OK;
        }
        else
        {
            cursor.lastPutStatus = CursoredLinkedList.PUT_STATUS_ERR;
        }
    }

    @Override
    public void replace(T value) {
        if(isValue())
        {
            remove();

            if(size() == 0)
            {
                putToEmpty(value);
            }
            else if(isHead())
            {
                putLeft(value);
                head();
            }
            else
            {
                putRight(value);
            }

            cursor.lastReplaceStatus = CursoredLinkedList.REPLACE_STATUS_OK;
        }
        else
        {
            cursor.lastReplaceStatus = CursoredLinkedList.REPLACE_STATUS_ERR;
        }
    }

    @Override
    public void remove()
    {
        if(isValue())
        {
            if(isHead())
            {
                cursor.head = cursor.current.nextNode;
                cursor.current = cursor.current.nextNode;
            }
            else if(isTail())
            {
                cursor.previous.nextNode = null;
                tail();
            }
            else
            {
                cursor.previous.nextNode = cursor.current.nextNode;
                cursor.current = cursor.current.nextNode;
            }
            cursor.listSize--;

            if(size() == 0)
            {
                cursor.isInitialized = false;
            }

            cursor.lastRemoveStatus = CursoredLinkedList.REMOVE_STATUS_OK;
        }
        else
        {
            cursor.lastRemoveStatus = CursoredLinkedList.REMOVE_STATUS_ERR;
        }
    }

    @Override
    public void removeAll(T value)
    {
        if(isValue())
        {
            head();
            do
            {
                if(cursor.current.value.equals(value))
                {
                    remove();
                }
                else
                {
                    next();
                }
            }while(!isTail() && getLastRemoveStatus() == CursoredLinkedList.REMOVE_STATUS_OK);
        }
        else
        {
            cursor.lastRemoveStatus = REMOVE_STATUS_ERR;
        }
    }

    @Override
    public void clear()
    {
        cursor.clear();
    }

    @Override
    public void head()
    {
        if(isValue())
        {
            cursor.previous = null;
            cursor.current = cursor.head;
        }
    }

    @Override
    public void tail()
    {
        if(isValue())
        {
            while(!isTail())
            {
                next();
            }
        }
    }

    @Override
    public void next()
    {
        if(isValue() && !isTail())
        {
            cursor.previous = cursor.current;
            cursor.current = cursor.current.nextNode;
        }
    }

    @Override
    public void find(T value)
    {
        if(isValue())
        {
            head();
            while (!cursor.current.value.equals(value) && !isTail()) {
                next();
            }

            if(cursor.current.value.equals(value))
            {
                cursor.lastFindStatus = CursoredLinkedList.FIND_STATUS_OK;
            }
            else
            {
                cursor.lastFindStatus = CursoredLinkedList.FIND_STATUS_ERR;
            }
        }
        else
        {
            cursor.lastFindStatus = CursoredLinkedList.FIND_STATUS_OK;
        }
    }

    @Override
    public int size() {
        return cursor.listSize;
    }

    @Override
    public int getLastGetStatus() {
        return cursor.lastGetStatus;
    }

    @Override
    public int getLastPutStatus() {
        return cursor.lastPutStatus;
    }

    @Override
    public int getLastRemoveStatus() {
        return cursor.lastRemoveStatus;
    }

    @Override
    public int getLastFindStatus() {
        return cursor.lastFindStatus;
    }

    @Override
    public int getLastReplaceStatus() {
        return cursor.lastReplaceStatus;
    }

    @Override
    public boolean isHead() {
        if(isValue())
            return cursor.previous == null;
        else
            return false;
    }

    @Override
    public boolean isTail() {
        if(isValue())
            return cursor.current.nextNode == null;
        else
            return false;
    }

    @Override
    public boolean isValue() {
        return cursor.isInitialized;
    }
}
