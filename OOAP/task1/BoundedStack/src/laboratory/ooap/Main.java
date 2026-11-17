package laboratory.ooap;

import laboratory.ooap.stack_m.BoundedStack;

public class Main
{
    public static void main(String[] args) {
        BoundedStack<Integer> stack = new BoundedStack<>();

        stack.push(1);
        stack.push(2);
        stack.push(3);

        Integer val = stack.peek();
        stack.pop();
    }
}
