from rest_framework import serializers
from .models import Product,Order,OrderItem
from django.contrib.auth.models import User
from django.contrib.auth import authenticate

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = ['id', 'name', 'price']

class OrderItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderItem
        fields = ['id', 'product_name', 'product_price', 'quantity']

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    class Meta:
        model = Order
        fields = ['id', 'user', 'created_at', 'items']
        read_only_fields = ['id', 'user', 'created_at']
class CreateOrderItemSerializer(serializers.Serializer):
    product_name = serializers.CharField(max_length=255)
    product_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    quantity = serializers.IntegerField()

class CreateOrderSerializer(serializers.Serializer):
    products = serializers.ListField(
        child=serializers.DictField(
            child=serializers.CharField(max_length=255)
        )
    )
    def create(self, validated_data):
        products_data = validated_data.pop('products')
        user = self.context['request'].user;
        order = Order.objects.create(user=user)
        for product_data in products_data:
            OrderItem.objects.create(
                order=order,
                product_name=product_data['product_name'],
                product_price=product_data['product_price'],
                quantity=product_data['quantity']
            )
        return order
class CustomAuthTokenSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField()

    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')
        user = authenticate(email=email, password=password)
        if not user:
            raise serializers.ValidationError('無效的電子郵件或密碼')
        attrs['user'] = user
        return attrs
    
    @property
    def validated_data(self):
        # Override to provide better type hints
        data = super().validated_data
        return data