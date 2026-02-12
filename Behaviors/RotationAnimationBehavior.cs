using System;
using System.Collections.Generic;
using System.Text;

namespace WonderWall.Behaviors;

public class RotationAnimationBehavior : Behavior<VisualElement>
{
    public static readonly BindableProperty RotationValueProperty = BindableProperty.Create(nameof(RotationValue), typeof(double), typeof(RotationAnimationBehavior), 0.0, propertyChanged: OnRotationValueChanged);

    public double RotationValue
    {
        get => (double)GetValue(RotationValueProperty);
        set => SetValue(RotationValueProperty, value);
    }

    private static async void OnRotationValueChanged(BindableObject bindable, object oldValue, object newValue)
    {
        if (bindable is RotationAnimationBehavior behavior && behavior.AssociatedObject != null)
        {
            await behavior.AssociatedObject.RotateToAsync((double)newValue, 200, Easing.CubicInOut);
        }
    }

    public VisualElement? AssociatedObject { get; private set; }

    protected override void OnAttachedTo(VisualElement bindable)
    {
        base.OnAttachedTo(bindable);
        AssociatedObject = bindable;
        BindingContext = AssociatedObject!.BindingContext;
        AssociatedObject.BindingContextChanged += AssociatedObject_BindingContextChanged;
    }

    protected override void OnDetachingFrom(VisualElement bindable)
    {
        base.OnDetachingFrom(bindable);
        AssociatedObject!.BindingContextChanged -= AssociatedObject_BindingContextChanged;
        AssociatedObject = null;
    }

    private void AssociatedObject_BindingContextChanged(object? sender, EventArgs e)
    {
        BindingContext = AssociatedObject!.BindingContext;
    }
}