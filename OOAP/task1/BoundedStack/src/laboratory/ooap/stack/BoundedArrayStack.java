package laboratory.ooap.stack;

import java.util.ArrayList;
import java.util.List;

public class BoundedArrayStack<T> extends BoundedStack<T>
{
    private List<T> stack; //main storage
    private final int maxCapacity; //max List size. Default value = DEFAULT_CAPACITY

    //Commands statuses
    private int peekStatus; //peek status
    private int popStatus; //pop status
    private int pushStatus; //push status

    public BoundedArrayStack() // Constructor with default capacity.
    {
        this.stack = new ArrayList<>(DEFAULT_CAPACITY);
        this.maxCapacity = DEFAULT_CAPACITY;

        peekStatus = PEEK_NIL;
        popStatus = POP_NIL;
        pushStatus = PUSH_NIL;
    }

    public BoundedArrayStack(int maxCapacity) // Constructor with defined capacity
    {
        this.stack = new ArrayList<>(maxCapacity);
        this.maxCapacity = maxCapacity;

        peekStatus = PEEK_NIL;
        popStatus = POP_NIL;
        pushStatus = PUSH_NIL;
    }

    @Override
    public void push(T value)
    {
        if(size() < this.maxCapacity)
        {
            stack.add(value);
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
            peekStatus = PEEK_OK;
            result = stack.get(size() - 1);
        }
        else
        {
            peekStatus = PEEK_ERR;
        }

        return result;
    }

    @Override
    public void pop()
    {
        if(size() > 0)
        {
            stack.remove(size() - 1);
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
