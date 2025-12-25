"""
Definition of views.
"""

# Django imports
from django.contrib.auth.models import User 
from django.contrib.auth.hashers import make_password
from django.core.cache import cache
from django.core.exceptions import ValidationError
from django.db import IntegrityError, DatabaseError

# Django REST Framework imports
from rest_framework import status
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import ValidationError as DRFValidationError

# JWT imports
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.authentication import JWTAuthentication

# Local imports
from .models import Product, Order
from .serializers import ProductSerializer, OrderSerializer, CreateOrderSerializer, CustomAuthTokenSerializer

# Python standard library
import random
import logging
from typing import cast, Dict, Any

# Set up logging
logger = logging.getLogger(__name__)


class UserRegistrationView(APIView):
    """
    註冊 API：存儲用戶的姓名、密碼、驗證碼和電子郵件。
    """
    permission_classes = [AllowAny]

    def post(self, request):
        self.check_permissions(request)

        username = request.data.get('username')
        email = request.data.get('email')
        password = request.data.get('password')
        verification_code = request.data.get('verification_code')

        # 驗證電子郵件格式
        if email and ('@' not in email or '.' not in email.split('@')[-1]):
            return Response(
                {'message': '電子郵件格式錯誤'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        # 檢查密碼強度(至少8個字元，包含字母和數字)
        if password and (len(password) < 8 or not any(c.isalpha() for c in password) or not any(c.isdigit() for c in password)):
            return Response(
                {'message': '密碼強度不足，請至少包含8個字元，並包含字母和數字'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        if not username or not email or not password or not verification_code:
            return Response(
                {'message': '需要完整郵件、名稱、密碼與驗證碼'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        if User.objects.filter(email=email).exists():
            return Response(
                {'message': '此郵件已被註冊'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        if User.objects.filter(username=username).exists():
            return Response(
                {'message': '使用者名稱重複'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        try:
            User.objects.create_user(email=email, username=username, password=password)
            return Response(
                {'message': '註冊成功'},
                status=status.HTTP_201_CREATED,
                content_type='application/json; charset=utf-8'
            )
        except IntegrityError as e:
            print(f"User registration integrity error: {str(e)}")
            return Response(
                {'message': '註冊失敗，用戶資料衝突'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError as e:
            print(f"User registration database error: {str(e)}")
            return Response(
                {'message': '資料庫錯誤，請稍後再試'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )


class UserLoginView(ObtainAuthToken):
    """
    登入 API：使用電子郵件和密碼進行驗證。
    """
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        self.check_permissions(request)

        serializer = CustomAuthTokenSerializer(data=request.data, context={'request': request})
        if not serializer.is_valid():
            return Response(
                {'message': '電子郵件或密碼輸入錯誤'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        # At this point, we know validation passed and user exists
        validated_data = cast(Dict[str, Any], serializer.validated_data)
        user = validated_data['user']

        # Create JWT tokens
        refresh = RefreshToken.for_user(user)
        access_token = refresh.access_token
        
        return Response({
            'message': '登入成功',
            'access_token': str(access_token),
            'refresh_token': str(refresh),
            'username': user.username,
        }, status=status.HTTP_200_OK, content_type='application/json; charset=utf-8')


class ProductListView(APIView):
    """
    商品 API：獲取商品列表。
    """
    permission_classes = [AllowAny]

    def get(self, request):
        self.check_permissions(request)

        try:
            products = Product.objects.all()
            serializer = ProductSerializer(products, many=True)
            return Response(
                {
                    "message": "商品列表取得成功",
                    "data": serializer.data
                },
                status=status.HTTP_200_OK,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError as e:
            print(f"Product list database error: {str(e)}")
            return Response(
                {
                    "message": "資料庫錯誤，請稍後再試",
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )
        except DRFValidationError as e:
            print(f"Product list serialization error: {str(e)}")
            return Response(
                {
                    "message": "資料序列化錯誤",
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )


class OrderManagementView(APIView):
    """
    訂單 API：傳出訂單列表、傳入訂單。
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        self.check_permissions(request)

        try:
            orders = Order.objects.filter(user=request.user)
            serializer = OrderSerializer(orders, many=True)
            return Response(
                {
                    "message": "訂單列表取得成功",
                    "data": serializer.data
                },
                status=status.HTTP_200_OK,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError as e:
            print(f"Order list database error: {str(e)}")
            return Response(
                {'message': '資料庫錯誤，請稍後再試'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )
        except DRFValidationError as e:
            print(f"Order list serialization error: {str(e)}")
            return Response(
                {'message': '資料序列化錯誤'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )

    def post(self, request):
        self.check_permissions(request)

        if not request.data or not any(request.data.values()):
            return Response(
                {
                    "message": "訂單建立失敗，沒有任何輸入資料",
                },
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        serializer = CreateOrderSerializer(data=request.data, context={'request': request})
        try:
            if serializer.is_valid():
                order = serializer.save(user=request.user)
                return Response(
                    {
                        "message": "訂單建立成功",
                        "data": OrderSerializer(order).data
                    },
                    status=status.HTTP_201_CREATED,
                    content_type='application/json; charset=utf-8'
                )
            return Response(
                {
                    "message": "訂單建立失敗，請確認輸入資料",
                    "errors": serializer.errors
                },
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )
        except IntegrityError as e:
            print(f"Order creation integrity error: {str(e)}")
            return Response(
                {
                    "message": "訂單建立失敗，資料衝突",
                },
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError as e:
            print(f"Order creation database error: {str(e)}")
            return Response(
                {
                    "message": "資料庫錯誤，請稍後再試",
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )
        except DRFValidationError as e:
            print(f"Order creation validation error: {str(e)}")
            return Response(
                {
                    "message": "訂單資料驗證失敗",
                },
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

    def delete(self, request, order_id):
        self.check_permissions(request)

        try:
            order = Order.objects.get(id=order_id, user=request.user)
            order.delete()
            return Response(
                {'message': '訂單移除成功'},
                status=status.HTTP_200_OK,
                content_type='application/json; charset=utf-8'
            )
        except Order.DoesNotExist:
            return Response(
                {'message': '訂單不存在或無權限操作'},
                status=status.HTTP_404_NOT_FOUND,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError as e:
            print(f"Order deletion database error: {str(e)}")
            return Response(
                {'message': '資料庫錯誤，請稍後再試'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )


class UserProfileView(APIView):
    """
    使用者 API：傳出用戶名稱與郵件
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        self.check_permissions(request)

        try:
            user = request.user
            if user.is_authenticated:
                data = {
                    "username": user.username,
                    "email": user.email
                }
                return Response(
                    {
                        "message": "用戶資料取得成功",
                        "data": data
                    },
                    status=status.HTTP_200_OK,
                    content_type='application/json; charset=utf-8'
                )
            else:
                return Response(
                    {'message': '使用者未登入'},
                    status=status.HTTP_401_UNAUTHORIZED,
                    content_type='application/json; charset=utf-8'
                )
        except DatabaseError as e:
            print(f"User profile database error: {str(e)}")
            return Response(
                {'message': '資料庫錯誤，請稍後再試'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )


class SendVerificationCodeView(APIView):
    """
    驗證碼 API：發送重設密碼驗證碼到用戶 email(僅測試用，實際專案請使用第三方服務)
    """
    permission_classes = [AllowAny]

    def post(self, request):
        self.check_permissions(request)

        email = request.data.get('email')
        if not email:
            return Response(
                {'message': '缺少 email'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        try:
            # 生成 6 位數驗證碼
            verification_code = str(random.randint(100000, 999999))
            cache.set(f'password_reset_{email}', verification_code, timeout=300)  # 5 分鐘有效

            # TODO: 用郵件發送驗證碼
            print(f'驗證碼發送到 {email}: {verification_code}')

            return Response(
                {'message': '驗證碼已發送'},
                status=status.HTTP_200_OK,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError as e:
            print(f"Verification code database error: {str(e)}")
            return Response(
                {'message': '資料庫錯誤，請稍後再試'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )


class PasswordResetView(APIView):
    """
    重設密碼 API
    """
    permission_classes = [AllowAny]

    def post(self, request):
        self.check_permissions(request)

        email = request.data.get('email')
        code = request.data.get('code')
        new_password = request.data.get('password')

        if not all([email, code, new_password]):
            return Response(
                {'message': '缺少必要參數'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        # 檢查密碼強度
        if len(new_password) < 8 or not any(c.isalpha() for c in new_password) or not any(c.isdigit() for c in new_password):
            return Response(
                {'message': '密碼強度不足，請至少包含8個字元，並包含字母和數字'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        cached_code = cache.get(f'password_reset_{email}')
        if cached_code != code:
            return Response(
                {'message': '驗證碼錯誤或已過期'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        try:
            user = User.objects.get(email=email)
            user.password = make_password(new_password)
            user.save()
            cache.delete(f'password_reset_{email}')  # 刪除驗證碼
            return Response(
                {'message': '密碼重設成功'},
                status=status.HTTP_200_OK,
                content_type='application/json; charset=utf-8'
            )
        except User.DoesNotExist:
            return Response(
                {'message': '用戶不存在'},
                status=status.HTTP_404_NOT_FOUND,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError as e:
            return Response(
                {'message': '資料庫錯誤，請稍後再試'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )
        except ValidationError as e:
            return Response(
                {'message': '密碼格式不正確'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )