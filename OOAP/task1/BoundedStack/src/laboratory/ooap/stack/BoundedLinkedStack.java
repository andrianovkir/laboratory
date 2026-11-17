package laboratory.ooap.stack;

import java.util.LinkedList;

public class BoundedLinkedStack<T> extends BoundedStack<T>
{
    private LinkedList<T> stack;
    private final int maxCapacity;

    //Commands statuses
    private int peekStatus; //peek status
    private int popStatus; //pop status
    private int pushStatus; //push status

    public BoundedLinkedStack()
    {
        this.stack = new LinkedList<>();
        this.maxCapacity = DEFAULT_CAPACITY;

        popStatus = POP_NIL;
        peekStatus = PEEK_NIL;
        pushStatus = PUSH_NIL;
    }

    public BoundedLinkedStack(int maxCapacity)
    {
        this.stack = new LinkedList<>();
        this.maxCapacity = maxCapacity;

        popStatus = POP_NIL;
        peekStatus = PEEK_NIL;
        pushStatus = PUSH_NIL;
    }

    @Override
    public void push(T value)
    {
        if(size() < maxCapacity)
        {
            stack.push(value);
            pushStatus = PUSH_OK;
        }
        else
        {
            pushStatus = PUSH_ERR;
        }
    }

    @Override
    public T peek()
    {
        T result = null; //Use default T value
        if(size() > 0)
        {
            result = stack.peek();
            peekStatus = PEEK_OK;
        }
        else
        {
            peekStatus = PEEK_ERR;
        }

        return result;
    }

    @Override
    public void pop() {
        if(size() > 0)
        {
            stack.pop();
            popStatus = POP_OK;
        }
        else
        {
            popStatus = POP_ERR;
        }
    }

    @Override
    public int size()
    {
        return stack.size();
    }

    @Override
    public void clear()
    {
        stack.clear();

        popStatus = POP_NIL;
        peekStatus = PEEK_NIL;
        pushStatus = PUSH_NIL;
    }

    @Override
    public int getMaxCapacity()
    {
        return maxCapacity;
    }

    @Override
    public int getPopStatus()
    {
        return popStatus;
    }

    @Override
    public int getPeekStatus()
    {
        return peekStatus;
    }

    @Override
    public int getPushStatus()
    {
        return pushStatus;
    }
}
